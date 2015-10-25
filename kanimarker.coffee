###

Kanimarker

Copyright (c) 2015 CALIL Inc.
This software is released under the MIT License.
http://opensource.org/licenses/mit-license.php

###

class Kanimarker
  # @property [ol.Map] マップオブジェクト（読み込み専用）
  map: null

  # @property [String] 表示モードの状態（読み込み専用）
  # normal ... 通常モード
  # centered ... 追従モード
  # headingup ... ヘディングアップモード
  mode: 'normal'

  # @property [Array<Number>] マーカーの位置（読み込み専用）
  position: null

  # @property [Number] マーカーの角度（読み込み専用）
  direction: 0

  # @property [Number] 計測精度・メートル（読み込み専用）
  accuracy: 0

  # @nodoc アニメーション用の内部ステート
  animations: {}

  # @nodoc デバッグ表示の有無(内部ステート)
  debug_: false

  # @nodoc コールバック用変数
  callbacks: {}

  # @property [Number] マーカー移動時のアニメーション時間(ms)
  moveDuration: 2000

  # @property [Number] 計測精度のアニメーション時間(ms)
  accuracyDuration: 2000

  # マップに現在地マーカーをインストールする
  #
  # @param map {ol.Map} マップオブジェクト
  #
  constructor: (map)->
    @map = map
    if @map?
      @map.on('postcompose', @postcompose_, this)
      @map.on('precompose', @precompose_, this)
      @map.on('pointerdrag', @pointerdrag_, this)

  # 現在進行中のアニメーションをキャンセルする
  #
  cancelAnimation: ->
    @animations = {}

  # デバッグ表示の有無を設定する
  #
  # @param value {Boolean}
  #
  setDebug: (value)->
    @debug_ = value
    @map.render()

  # 表示モードの設定をする
  #
  # @param mode {String} normal/centered/headingup
  # @return {Boolean} 切り替えが成功したか
  #
  setMode: (mode)->
    if mode isnt 'normal' and mode isnt 'centered' and mode isnt 'headingup'
      throw 'invalid mode'
    if @mode != mode
      if @position is null and (mode == 'centered' or mode == 'headingup')
        return false
      if @direction is null and mode == 'headingup'
        return false
      @mode = mode
      if @position isnt null and mode isnt 'normal'
        animated = false
        if mode is 'headingup'
          from = @map.getView().getRotation() * 180 / Math.PI % 360
          to = -@direction % 360
          diff = from - to
          if diff < -180
            diff = -360 - diff
          if diff > 180
            diff = diff - 360
          if Math.abs(diff) > 100
            d = 800
          else if Math.abs(diff) > 60
            d = 400
          else
            d = 300
          if from - to != 0
            animated = true
            @animations.moveMode = null
            @animations.rotationMode =
              start: new Date()
              from: diff
              to: 0
              duration: d
              animate: (frameStateTime)->
                time = (frameStateTime - @start) / @duration
                @current = @from + ((@to - @from) * ol.easing.easeOut(time))
                return time <= 1
        if not animated
          from = @map.getView().getCenter()
          to = @position
          if from[0] - to[0] != 0 or from[1] - to[1] != 0
            froms = [from[0] - to[0], from[1] - to[1]]
            if @animations.moveMode? and @animations.moveMode.animate()
              froms = [animations.current[0], animations.moveMode.current[1]]
            @animations.moveMode =
              start: new Date()
              from: froms
              to: [0, 0]
              duration: 800
              animate: (frameStateTime)->
                time = (frameStateTime - @start) / @duration
                @current = [@from[0] + ((@to[0] - @from[0]) * ol.easing.easeOut(time)),
                            @from[1] + ((@to[1] - @from[1]) * ol.easing.easeOut(time))]
                return time <= 1

        @map.getView().setCenter(@position)
      if mode == 'headingup'
        @map.getView().setRotation(-(@direction / 180 * Math.PI))
      else
        @map.render()
      @dispatch('change:mode', @mode)
      return true

  # 現在地を設定する
  #
  # @param toPosition {Array} 新しい現在地
  # @param accuracy {Number} 計測精度 nullの場合は前回の値を維持
  # @param silent {Boolean} 再描画抑制フラグ
  #
  setPosition: (toPosition, accuracy, silent = false)->
    # 変化がない場合は何もしない
    if (toPosition? and @position? and toPosition[0] == @position[0] and toPosition[1] == @position[1]) or (not toPosition? and not @position?)
      if accuracy?
        @setAccuracy(accuracy, silent)
      return
    if accuracy?
      @setAccuracy(accuracy, true)

    # 移動中の場合は中間地点からスタートする
    if @animations.move?
      fromPosition = @animations.move.current
    else
      fromPosition = @position
    @position = toPosition

    # 追従モードの場合はマップに場所をセットする
    if @mode isnt 'normal' and toPosition?
      @map.getView().setCenter(toPosition.slice())

    # スタート地点から目的地に移動する
    if fromPosition? and toPosition?
      @animations.move =
        start: new Date()
        from: fromPosition.slice()
        to: toPosition.slice()
        duration: @moveDuration
        animate: (frameStateTime)->
          time = (frameStateTime - @start) / @duration
          if @duration > 8000
            easing = ol.easing.linear(time)
          else if  @duration > 2000
            easing = ol.easing.inAndOut(time)
          else
            easing = ol.easing.easeOut(time)
          @current = [@from[0] + ((@to[0] - @from[0]) * easing),
                      @from[1] + ((@to[1] - @from[1]) * easing)]
          return time <= 1

    # フェードイン
    if not fromPosition? and toPosition?
      @animations.fade =
        start: new Date()
        from: 0
        to: 1
        position: toPosition
        animate: (frameStateTime)->
          time = (frameStateTime - @start) / 500
          @current = @from + ((@to - @from) * ((x)-> x)(time))
          return time <= 1

    # フェードアウト
    if fromPosition? and not toPosition?
      if @mode isnt 'normal'
        @setMode 'normal'
      @animations.move = null
      @animations.fade =
        start: new Date()
        from: 1
        to: 0
        position: fromPosition
        animate: (frameStateTime)->
          time = (frameStateTime - @start) / 500
          @current = @from + ((@to - @from) * ((x)-> x)(time))
          return time <= 1

    if not silent
      @map.render()

  # 計測精度を設定する
  #
  # @param accuracy {Number} 計測精度（単位はメートル）
  # @param silent {Boolean} 再描画抑制フラグ
  #
  setAccuracy: (accuracy, silent = false)->
    if @accuracy is accuracy
      return
    # アニメーション中の場合は中間値からスタート
    if @animations.accuracy? and @animations.accuracy.animate()
      from = @animations.accuracy.current
    else
      from = @accuracy
    @accuracy = accuracy
    @animations.accuracy =
      start: new Date()
      from: from
      to: accuracy
      duration: @accuracyDuration
      animate: (frameStateTime)->
        time = (frameStateTime - @start) / @duration
        @current = @from + ((@to - @from) * ol.easing.easeOut(time))
        return time <= 1
    if not silent
      @map.render()

  # マーカーの向きを設定する
  #
  # @param newDirection {Number} 真北からの角度
  # @param silent {Boolean} 再描画抑制フラグ
  #
  setHeading: (direction, silent = false)->
    if direction is undefined or @direction is direction
      return
    diff = @direction - direction
    if diff < -180
      diff = -360 - diff
    if diff > 180
      diff = diff - 360
    @animations.heading =
      start: new Date()
      from: direction + diff
      to: direction
      animate: (frameStateTime)->
        time = (frameStateTime - @start) / 500
        @current = @from + ((@to - @from) * ol.easing.easeOut(time))
        return time <= 1

    @direction = direction

    if @mode is 'headingup' # 追従モードの場合は先にセットする
      @map.getView().setRotation(-(@direction / 180 * Math.PI))
    else if not silent
      @map.render()

  # @nodoc マップ描画処理
  postcompose_: (event)->
    context = event.context
    vectorContext = event.vectorContext
    frameState = event.frameState
    pixelRatio = frameState.pixelRatio

    # default value
    opacity = 1
    position = @position
    accuracy = @accuracy
    direction = @direction

    if @animations.move?
      if @animations.move.animate(frameState.time)
        position = @animations.move.current
        frameState.animate = true
      else
        @animations.move = null

    if @animations.fade?
      if @animations.fade.animate(frameState.time)
        opacity = @animations.fade.current
        position = @animations.fade.position
        frameState.animate = true
      else
        @animations.fade = null

    if @animations.heading?
      if @animations.heading.animate(frameState.time)
        direction = @animations.heading.current
        frameState.animate = true
      else
        @animations.heading = null

    if @animations.accuracy?
      if @animations.accuracy.animate(frameState.time)
        accuracy = @animations.accuracy.current
        frameState.animate = true
      else
        @animations.accuracy = null

    # 非表示以外なら描画
    if position?
      accuracySize = (accuracy / frameState.viewState.resolution)
      maxSize = Math.max(@map.getSize()[0],@map.getSize()[1])
      if accuracySize > 3 and accuracySize * pixelRatio < maxSize
        opacity_ = 0.2 * opacity
        if accuracySize < 30
          opacity_ = opacity_ * (accuracySize / 30)
        if accuracySize * pixelRatio > maxSize * 0.2
          diff = accuracySize * pixelRatio - maxSize * 0.2
          opacity_ = opacity_ * (1-diff / (maxSize * 0.4))
          if opacity_<0
            opacity_=0

        circleStyle = new ol.style.Circle(
          snapToPixel: false
          radius: accuracySize * pixelRatio
          fill: new ol.style.Fill(
            color: "rgba(56, 149, 255, #{opacity_})")
        )
        vectorContext.setImageStyle(circleStyle)
        vectorContext.drawPointGeometry(new ol.geom.Point(position), null)

      # マーカーアイコン
      iconStyle = new ol.style.Circle(
        radius: 8 * pixelRatio
        snapToPixel: false
        fill: new ol.style.Fill(color: "rgba(0, 160, 233, #{opacity})")
        stroke: new ol.style.Stroke(
          color: "rgba(255, 255, 255, #{opacity})"
          width: 3 * pixelRatio)
      )
      vectorContext.setImageStyle(iconStyle)
      vectorContext.drawPointGeometry(new ol.geom.Point(position), null)

      context.save()

      if @mode != 'normal'
        if @animations.moveMode?
          if @animations.moveMode.animate(frameState.time)
            position = position.slice()
            position[0] -= @animations.moveMode.current[0]
            position[1] -= @animations.moveMode.current[1]
            frameState.animate = true
            pixel = @map.getPixelFromCoordinate(position)
            context.translate(pixel[0] * pixelRatio, pixel[1] * pixelRatio)
          else
            @animations.moveMode = null
            context.translate(context.canvas.width / 2, context.canvas.height / 2)
        else
          context.translate(context.canvas.width / 2, context.canvas.height / 2)
      else
        pixel = @map.getPixelFromCoordinate(position)
        context.translate(pixel[0] * pixelRatio, pixel[1] * pixelRatio)
      context.rotate((direction / 180 * Math.PI) + frameState.viewState.rotation)
      context.scale(pixelRatio, pixelRatio)
      context.beginPath()
      context.moveTo(0, -20)
      context.lineTo(-7, -12)
      context.lineTo(7, -12)
      context.closePath()
      context.fillStyle = "rgba(0, 160, 233, #{opacity})"
      context.strokeStyle = "rgba(255, 255, 255, #{opacity})"
      context.lineWidth = 3
      context.fill()

      context.restore() #キャンバスのステートを復帰(必ず実行すること)

    if @debug_
      txt = ('Position:' + @position +
        ' Heading:' + @direction +
        ' Accuracy:' + @accuracy +
        ' Mode:' + @mode )
      if @animations.move? then txt += ' [Move]'
      if @animations.heading? then txt += ' [Rotate]'
      if @animations.accuracy? then txt += ' [Accuracy]'
      if @animations.fade? then txt += ' [Fadein/Out]'
      if @animations.rotationMode? then txt += ' [HeadingRotation]' + @animations.rotationMode.current

      context.save()
      context.fillStyle = "rgba(255, 255, 255, 0.6)"
      context.fillRect(0, context.canvas.height - 20, context.canvas.width, 20)
      context.font = "10px"
      context.fillStyle = "black"
      context.fillText(txt, 10, context.canvas.height - 7)
      context.restore()

  # @nodoc マップ描画前の処理
  precompose_: (event)->
    if @position isnt null and @mode != 'normal'
      frameState = event.frameState
      position = @position
      if @animations.move?
        if @animations.move.animate(frameState.time)
          position = @animations.move.current
        else
          @animations.move = null
      if @animations.moveMode?
        if @animations.moveMode.animate(frameState.time)
          position = position.slice()
          position[0] += @animations.moveMode.current[0]
          position[1] += @animations.moveMode.current[1]
          frameState.animate = true
        else
          @animations.moveMode = null
      frameState.viewState.center[0] = position[0]
      frameState.viewState.center[1] = position[1]
      if @mode == 'headingup'
        direction = @direction
        if @animations.heading?
          if @animations.heading.animate(frameState.time)
            direction = @animations.heading.current
          else
            @animations.heading = null

        diff = 0
        if @animations.rotationMode?
          if @animations.rotationMode.animate(frameState.time)
            diff = @animations.rotationMode.current
            frameState.animate = true
          else
            @animations.rotationMode = null
        frameState.viewState.rotation = -((direction - diff) / 180 * Math.PI)

  # @nodoc ドラッグイベントの処理
  pointerdrag_: ->
    if @mode isnt 'normal'
      @setMode('normal')

  # イベントハンドラーを設定する
  #
  # @param event_name {String} イベント名
  # @param callback {function} コールバック関数
  # change:headingup (newvalue) - 追従モードの変更を通知する
  on: (type, listener) ->
    @callbacks[type] ||= []
    @callbacks[type].push listener
    @

  # @nodoc イベントを通知する
  dispatch: (type, data) ->
    chain = @callbacks[type]
    callback data for callback in chain if chain?

if typeof exports isnt 'undefined'
  module.exports = Kanimarker