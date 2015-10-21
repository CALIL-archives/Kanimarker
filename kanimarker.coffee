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
  moveAnimationState_: null
  directionAnimationState_: null
  accuracyAnimationState_: null
  fadeInOutAnimationState_: null

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
    @map.on('postcompose', @postcompose_, this)
    @map.on('precompose', @precompose_, this)
    @map.on('pointerdrag', @pointerdrag_, this)

  # 現在進行中のアニメーションをキャンセルする
  #
  cancelAnimation: ->
    @moveAnimationState_ = null
    @directionAnimationState_ = null
    @accuracyAnimationState_ = null
    @fadeInOutAnimationState_ = null

  # デバッグ表示の有無を設定する
  #
  # @param newValue {Boolean} normal/centered/headingup
  #
  showDebugInformation: (newValue)->
    @debug_ = newValue
    @map.render()

  # 表示モードの設定をする
  #
  # @param newMode {String} normal/centered/headingup
  # @return {Boolean} 切り替えが成功したか
  setMode: (newMode)->
    if newMode isnt 'normal' and newMode isnt 'centered' and newMode isnt 'headingup'
      throw 'invalid mode'
    if @mode != newMode
      if @position is null and (newMode == 'centered' or newMode == 'headingup')
        return false
      if @direction is null and newMode == 'headingup'
        return false
      @mode = newMode
      @cancelAnimation()
      if @position isnt null
        @map.getView().setCenter(@position.slice())
      if newMode == 'headingup'
        @map.getView().setRotation(-(@direction / 180 * Math.PI))
      @map.render()
      @dispatch('change:mode', newMode)
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
    if @moveAnimationState_?
      fromPosition = @moveAnimationState_.current
    else
      fromPosition = @position
    @position = toPosition

    # 追従モードの場合はマップに場所をセットする
    if @mode isnt 'normal' and toPosition?
      @map.getView().setCenter(toPosition.slice())

    # スタート地点から目的地に移動する
    if fromPosition? and toPosition?
      @moveAnimationState_ =
        start: new Date()
        from: fromPosition.slice()
        current: fromPosition.slice()
        to: toPosition.slice()
        duration: @moveDuration
        animate: (frameStateTime)->
          time = (frameStateTime - @start) / @duration
          if @duration > 8000
            @current[0] = @from[0] + ((@to[0] - @from[0]) * ol.easing.linear(time))
            @current[1] = @from[1] + ((@to[1] - @from[1]) * ol.easing.linear(time))
          else if @duration > 2000
            @current[0] = @from[0] + ((@to[0] - @from[0]) * ol.easing.inAndOut(time))
            @current[1] = @from[1] + ((@to[1] - @from[1]) * ol.easing.inAndOut(time))
          else
            @current[0] = @from[0] + ((@to[0] - @from[0]) * ol.easing.easeOut(time))
            @current[1] = @from[1] + ((@to[1] - @from[1]) * ol.easing.easeOut(time))
          return time <= 1

    # フェードイン
    if not fromPosition? and toPosition?
      @fadeInOutAnimationState_ =
        start: new Date()
        from: 0
        current: 0
        to: 1
        animationPosition: toPosition
        animate: (frameStateTime)->
          time = (frameStateTime - @start) / 500
          @current = @from + ((@to - @from) * ((x)-> x)(time))
          return time <= 1

    # フェードアウト
    if fromPosition? and not toPosition?
      if @mode isnt 'normal'
        @setMode 'normal'
      @moveAnimationState_ = null
      @fadeInOutAnimationState_ =
        start: new Date()
        from: 1
        current: 1
        to: 0
        animationPosition: fromPosition
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
    if @accuracyAnimationState_?
      from = @accuracyAnimationState_.current
    else
      from = @accuracy
    @accuracy = accuracy
    @accuracyAnimationState_ =
      start: new Date()
      from: from
      to: accuracy
      current: from
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
  setDirection: (newDirection, silent = false)->
    if newDirection is undefined or @direction == newDirection
      return

    rotation = @direction
    while rotation < -180
      rotation += 360
    while rotation > 180
      rotation -= 360

    @directionAnimationState_ =
      start: new Date()
      from: rotation
      to: newDirection
      animate: (frameStateTime)->
        time = (frameStateTime - @start) / 500
        @current = @from + ((@to - @from) * ol.easing.easeOut(time))
        return time <= 1

    @direction = newDirection

    if @mode is 'headingup' # 追従モードの場合は先にセットする
      @map.getView().setRotation(-(newDirection / 180 * Math.PI))
    else if not silent
      @map.render()

  # @nodoc マップ描画処理
  postcompose_: (event)->
    context = event.context
    vectorContext = event.vectorContext
    frameState = event.frameState
    pixelRatio = frameState.pixelRatio

    # アニメーションしてない時の値
    opacity = 1
    position = @position
    accuracy = @accuracy
    direction = @direction

    # 位置アニメーション
    if @moveAnimationState_?
      if @moveAnimationState_.animate(frameState.time)
        position = @moveAnimationState_.current
        frameState.animate = true
      else
        @moveAnimationState_ = null

    # フェードインアウトアニメーション
    if @fadeInOutAnimationState_?
      if @fadeInOutAnimationState_.animate(frameState.time)
        opacity = @fadeInOutAnimationState_.current
        position = @fadeInOutAnimationState_.animationPosition
        frameState.animate = true
      else
        @fadeInOutAnimationState_ = null

    # 回転アニメーション
    if @directionAnimationState_?
      if @directionAnimationState_.animate(frameState.time)
        direction = @directionAnimationState_.current
        frameState.animate = true
      else
        @directionAnimationState_ = null

    # 円アニメーション
    if @accuracyAnimationState_?
      if @accuracyAnimationState_.animate(frameState.time)
        accuracy = @accuracyAnimationState_.current
        frameState.animate = true
      else
        @accuracyAnimationState_ = null

    # 非表示以外なら描画
    if position?
      # 円
      if (accuracy / frameState.viewState.resolution) * pixelRatio > 15
        circleStyle = new ol.style.Circle(
          snapToPixel: false
          radius: (accuracy / frameState.viewState.resolution) * pixelRatio
          fill: new ol.style.Fill(
            color: "rgba(56, 149, 255, #{0.2 * opacity})")
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

      # 矢印
      context.save() #キャンバスのステートをバックアップ

      # heading up なら画面中央にマーカーを移動
      if @mode != 'normal'
        context.translate(context.canvas.width / 2, context.canvas.height / 2)
      else
        pixel = @map.getPixelFromCoordinate(position)
        context.translate(pixel[0] * pixelRatio, pixel[1] * pixelRatio)

      # 座標空間をcoordinateを中心にdig度回転する
      # この時、マップ全体の回転も考慮する必要がある
      context.rotate((direction / 180 * Math.PI) + frameState.viewState.rotation)

      # retina 対応
      context.scale(pixelRatio, pixelRatio)

      # 矢印のパスを定義(このパスはSVGからでも移植できるけど、原点に注意)
      context.beginPath()
      context.moveTo(0, -20)
      context.lineTo(-7, -12)
      context.lineTo(7, -12)
      context.closePath()

      # 塗りつぶす。ここでstrokeやfill、スタイルをセット
      context.fillStyle = "rgba(0, 160, 233, #{opacity})"
      context.strokeStyle = "rgba(255, 255, 255, #{opacity})"
      context.lineWidth = 3
      context.fill()
      context.restore() #キャンバスのステートを復帰(必ず実行すること)

    if @debug_
      debugText = ('Position:' + kanimarker.position +
        ' Heading:' + kanimarker.direction +
        ' Accuracy:' + kanimarker.accuracy +
        ' Mode:' + kanimarker.mode )
      if kanimarker.moveAnimationState_? then debugText+=' [Move]'
      if kanimarker.directionAnimationState_? then debugText+=' [Rotate]'
      if kanimarker.accuracyAnimationState_? then debugText+=' [Accuracy]'
      if kanimarker.fadeInOutAnimationState_? then debugText+=' [Fadein/Out]'
      context.save()
      context.fillStyle = "rgba(255, 255, 255, 0.6)"
      context.fillRect(0, context.canvas.height - 20, context.canvas.width, 20)
      context.font = "10px"
      context.fillStyle = "black"
      context.fillText(debugText, 10, context.canvas.height - 7)
      context.restore()

  # @nodoc マップ描画前の処理
  precompose_: (event)->
    if @position isnt null and @mode != 'normal'
      frameState = event.frameState
      position = @position
      if @moveAnimationState_?
        if @moveAnimationState_.animate(frameState.time)
          position = @moveAnimationState_.current
        else
          @moveAnimationState_ = null
      frameState.viewState.center[0] = position[0]
      frameState.viewState.center[1] = position[1]
      if @mode == 'headingup'
        direction = @direction
        if @directionAnimationState_?
          if @directionAnimationState_.animate(frameState.time)
            direction = @directionAnimationState_.current
          else
            @directionAnimationState_ = null
        frameState.viewState.rotation = -(direction / 180 * Math.PI)

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