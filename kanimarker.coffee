###
  OpenLayers 3 でマーカーを表示するクラス

  @example マーカーを 表示/非表示 する
    kanimarker = new Kanimarker(map)
    kanimarker.setPosition(point, accuracy = 50)
    kanimarker.setPosition(null)

  @author sakai@calil.jp
  @version 1.2
###
class Kanimarker

  deepCopy = (object)->
    return JSON.parse(JSON.stringify(object))

  # @property [ol.Map] ◯ OpenLayers3 マップオブジェクト
  map: null

  # @property [Boolean] ◯ ヘディングアップしているかどうか (している: true, してない: false)
  headingUp: false

  # @property [Array<Number>] ◯ マーカーの現在の位置 (マーカーが非表示の時: null)
  position: null

  # @property [Number] ◯ マーカーの向き (0 - 360)
  direction: null

  # @property [Number] ◯ 円のサイズ (メートル)
  accuracy: null

  # @property [Function] ◯ 移動アニメーション postcompose, precompose から呼ばれる (アニメーションしていない時: null)
  positionAnimation: null

  # @property [Function] ◯ 回転アニメーション postcompose, precompose から呼ばれる (アニメーションしていない時: null)
  directionAnimation: null

  # @property [Function] ◯ 円のサイズ変更アニメーション postcompose から呼ばれる (アニメーションしていない時: null)
  circleAnimation: null

  # @property [Function] 表示/非表示アニメーション postcompose, から呼ばれる (アニメーションしていない時: null)
  opacityAnimation: null

  ###
    mapを指定してマーカーを生成
    @param @map {ol.Map} - OpenLayers3 マップオブジェクト
    @classdesc OpenLayers3に現在地マーカーを表示するクラス.
    @constructor
  ###
  constructor: (@map)->
    @accuracy = 0
    @direction = 0

    @map.on('postcompose', @postcompose_, this)
    @map.on('precompose', @precompose_, this)
    @map.on('pointerdrag', @pointerdrag_, this)

  ###
    現在地を常に中心, マーカーの向きを画面上向きにするかどうかを設定する.
    @param headingUp {Boolean} する:true, しない: false
    @return 成功: true 現在地、または角度がセットされていない: false
  ###
  setHeadingUp: (newHeadingUp = false)->
    @headingUp = newHeadingUp

    # ヘディングアップへ変わったら再描画する
    if @headingUp
      @positionAnimation = null
      @directionAnimation = null
      if @position?
        @map.getView().setCenter(deepCopy(@position))
        return false

      if @direction?
        @map.getView().setRotation(-(@direction / 180 * Math.PI))
        return false
    return true

  # 現在のマーカーのいちへ移動
  # @nodoc
  toCurrentPosition: ->
    if @position?
      @map.getView().setCenter(deepCopy(@position))
    return

  ###
    現在地マーカーを移動する
    @param toPosition {Array} 現在地を描画する座標
    @param accuracy {Number} 円の広さ (メートル) 指定がない場合は変更されない
    @param silent {Boolean} renderをしない時に true にする. default: false
  ###
  setPosition: (toPosition, accuracy, silent = false)->
    _this = this

    if @positionAnimation?
      fromPosition = @positionAnimation.current
      @positionAnimation = null
    else
      fromPosition = @position

    if toPosition == fromPosition
      # 何もしない
      return

    if toPosition? and fromPosition?
      # 移動
      @positionAnimation =
        start: new Date()
        from: deepCopy(fromPosition)
        current: deepCopy(fromPosition)
        to: deepCopy(toPosition)

        animate: (frameStateTime)->
          time = (frameStateTime - @start) / 2000

          if time <= 1
            @current[0] = @from[0] + ((@to[0] - @from[0]) * ol.easing.easeOut(time))
            @current[1] = @from[1] + ((@to[1] - @from[1]) * ol.easing.easeOut(time))
            return true
          else
            _this.positionAnimation = null # アニメーションが終わると消滅する
            return false

    else if toPosition?
      # 表示
      if @opacityAnimation?
        from = @opacityAnimation.current
      else
        from = 0
      @opacityAnimation =
        start: new Date()
        from: from
        current: from
        to: 1
        animationPosition: toPosition

        animate: (frameStateTime)->
          time = (frameStateTime - @start) / 500

          if time <= 1
            @current = @from + ((@to - @from) * ((x)-> x)(time))
            return true
          else
            _this.opacityAnimation = null # アニメーションが終わると消滅する
            return false

    else
      # 非表示
      if @opacityAnimation?
        from = @opacityAnimation.current
      else
        from = 1
      @opacityAnimation =
        start: new Date()
        from: from
        current: from
        to: 0
        animationPosition: fromPosition

        animate: (frameStateTime)->
          time = (frameStateTime - @start) / 500

          if time <= 1
            @current = @from + ((@to - @from) * ((x)-> x)(time))
            return true
          else
            _this.opacityAnimation = null # アニメーションが終わると消滅する
            return false

    @position = toPosition

    if not silent
      @map.render()
    return

  ###
    現在地マーカーを非表示にする.
    表示するにはsetPosition()で現在地の場所を決める
  ###
  hide: ->
    @setPosition(null)

  ###
    現在地の周りの円の大きさを変える
    @param accuracy {Number} 広さ (メートル)
    @param silent {Boolean} renderをしない時に true にする. default: false
  ###
  setAccuracy: (accuracy, silent = false)->
    _this = this

    # 前のアニメーションのキャンセル
    if @circleAnimation?
      from = @circleAnimation.current
      @circleAnimation = null
    else
      from = @accuracy

    @circleAnimation =
      start: new Date()
      from: from
      current: from

      animate: (frameStateTime)->
        time = (frameStateTime - @start) / 2000

        if time <= 1
          @current = @from + ((_this.accuracy - @from) * ol.easing.easeOut(time))
          return true
        else
          _this.circleAnimation = null # アニメーションが終わると消滅する
          return false

    # 最新の値にする
    @accuracy = accuracy

    if not silent
      @map.render()

  ###
    現在地マーカーの向きを設定する.
    @param newDirection {Number} 真北からの角度
  ###
  setDirection: (newDirection, silent = off)->

    # アニメーションのための仮想的な角度
    # 左回りの場合はvirtualDirectionはマイナスの値になることがある
    if newDirection > @direction
      n = newDirection - @direction
      if n <= 180
        virtualDirection = @direction + n # 右回り n度回る
      else
        virtualDirection = @direction - (360 - n) # 左回り 360 - n度回る
    else
      n = @direction - newDirection
      if n <= 180
        virtualDirection = @direction - n # 左回り n度回る
      else
        virtualDirection = @direction + (360 - n) # 右回り 360 - n度回る

    _this = this
    @directionAnimation =
      start: new Date()
      from: @direction
      current: @direction
      to: virtualDirection

      animate: (frameStateTime)->
        time = (frameStateTime - @start) / 500

        if time <= 1
          @current = @from + ((@to - @from) * ol.easing.easeOut(time))
          return true
        else
          _this.directionAnimation = null # アニメーションが終わると消滅する
          return false

    @direction = newDirection
    if not silent
      @map.render()

  ###
    @private ol.Map on postcompose イベントリスナー ol.Map on から呼ばれる
  ###
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
    if @positionAnimation? and @positionAnimation.animate(frameState.time)
      position = @positionAnimation.current
      frameState.animate = true # アニメーションを続ける

    # 回転アニメーション
    if @directionAnimation? and @directionAnimation.animate(frameState.time)
      direction = @directionAnimation.current
      frameState.animate = true # アニメーションを続ける

    # 表示/非表示アニメーション
    if @opacityAnimation? and @opacityAnimation.animate(frameState.time)
      opacity = @opacityAnimation.current
      position = @opacityAnimation.animationPosition
      frameState.animate = true # アニメーションを続ける

    # 円アニメーション
    if @circleAnimation? and @circleAnimation.animate(frameState.time)
      # アニメーション中
      accuracy = @circleAnimation.current
      frameState.animate = true # アニメーションを続ける

    # 非表示以外なら描画
    if position?
      # 円
      circleStyle = new ol.style.Circle(
        radius: (accuracy / frameState.viewState.resolution) * pixelRatio
        fill: new ol.style.Fill(
          color: "rgba(56, 149, 255, #{0.2 * opacity})")
        stroke: new ol.style.Stroke(
          color: "rgba(56, 149, 255, #{0.8 * opacity})"
          width: 1 * pixelRatio)
      )
      vectorContext.setImageStyle(circleStyle)
      vectorContext.drawPointGeometry(new ol.geom.Point(position), null)

      # マーカーアイコン
      iconStyle = new ol.style.Circle(
        radius: 8 * pixelRatio
        snapToPixel: false
        fill: new ol.style.Fill(color: "rgba(0, 160, 233, #{1.0 * opacity})")
        stroke: new ol.style.Stroke(
          color: "rgba(255, 255, 255, #{1.0 * opacity})"
          width: 3 * pixelRatio)
      )
      vectorContext.setImageStyle(iconStyle)
      vectorContext.drawPointGeometry(new ol.geom.Point(position), null)

      # 矢印
      context.save() #キャンバスのステートをバックアップ

      # heading up なら画面中央にマーカーを移動
      if @headingUp
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
      context.moveTo(0, -25)
      context.lineTo(-10, -12)
      context.lineTo(10, -12)
      context.closePath()

      # 塗りつぶす。ここでstrokeやfill、スタイルをセット
      context.fillStyle = "rgba(0, 160, 233, #{1.0 * opacity})"
      context.strokeStyle = "rgba(255, 255, 255, #{1.0 * opacity})"
      context.lineWidth = 3
      context.fill()
      context.stroke()

      context.restore() #キャンバスのステートを復帰(必ず実行すること)

    $('#marker_info').text(JSON.stringify(
      '現在地ステータス': kanimarker.position
      '回転': kanimarker.direction
      '円のサイズ': kanimarker.accuracy
      '表示/非表示': `(kanimarker.position != null) ? '表示' : '非表示'`
      '表示モード': `kanimarker.headingUp ? '追従モード' : 'ビューモード'`
      '移動中': `(kanimarker.positionAnimation != null) ? 'アニメーション中' : 'アニメーションなし'`
      '回転中': `(kanimarker.directionAnimation != null) ? 'アニメーション中' : 'アニメーションなし'`
      '円の拡大/縮小': `(kanimarker.circleAnimation != null) ? 'アニメーション中' : 'アニメーションなし'`
      '表示/非表示': `(kanimarker.opacityAnimation != null) ? 'アニメーション中' : 'アニメーションなし'`
    , null, 2))

    return

  ###
    @private ol.Map on precompose イベントリスナー ol.Map on から呼ばれる
  ###
  precompose_: (event)->
    frameState = event.frameState
    if @position?
      # 現在地を中心に固定
      if @headingUp
        position = @position
        direction = @direction

        # 位置アニメーション
        if @positionAnimation?
          if @positionAnimation.animate(frameState.time)
            position = @positionAnimation.current
          else
            # ラスト1回はView本体の中心を上書き(renderを呼び続けないための対策)
            @map.getView().setCenter(deepCopy(@position))

        # 回転アニメーション
        if @directionAnimation?
          if @directionAnimation.animate(frameState.time)
            direction = @directionAnimation.current
          else
            # ラスト1回はView本体の回転方向を上書き(renderを呼び続けないための対策)
            @map.getView().setRotation(-(direction / 180 * Math.PI))

        # レイヤーに反映
        frameState.viewState.center[0] = position[0]
        frameState.viewState.center[1] = position[1]

        frameState.viewState.rotation = -(direction / 180 * Math.PI)
    return

  ###
    @private マップがドラッグされた時に呼ばれる
  ###
  pointerdrag_: ->
    if @headingUp
      @setHeadingUp(false)
    return
