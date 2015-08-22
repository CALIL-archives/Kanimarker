#
#  現在地マーカーを表示するOpenLayers3プラグイン
#
#  @author sakai@calil.jp
#  @author ryuuji@calil.jp
#

class Kanimarker

  # @property [ol.Map] マップオブジェクト（読み込み専用）
  map: null

  # @property [Boolean] 追従モードの状態（読み込み専用）
  headingUp: false

  # @property [Array<Number>] マーカーの位置（読み込み専用）
  position: null

  # @property [Number] マーカーの角度（読み込み専用）
  direction: 0

  # @property [Number] 計測精度・メートル（読み込み専用）
  accuracy: 0

  # @nodoc アニメーション用の内部ステート
  moveAnimationState_: null

  # @nodoc アニメーション用の内部ステート
  directionAnimationState_: null

  # @nodoc アニメーション用の内部ステート
  accuracyAnimationState_: null

  # @nodoc アニメーション用の内部ステート
  fadeInOutAnimationState_: null

  # 現在地マーカーをマップにインストールする
  #
  # @param map {ol.Map} マップオブジェクト
  #
  constructor: (map)->
    @map=map
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

  # 追従モードの設定をする
  #
  # @param newValue {Boolean} する:true, しない: false
  #
  setHeadingUp: (newValue)->
    @headingUp = newValue
    @cancelAnimation()
    if @position?
      @map.getView().setCenter(@position.slice())
    if @direction?
      @map.getView().setRotation(-(@direction / 180 * Math.PI))
    @map.render()

  # 現在地を設定する
  # @param toPosition {Array} 新しい現在地
  # @param accuracy {Number} 計測精度 nullの場合は前回の値を維持
  # @param silent {Boolean} 再描画抑制フラグ
  #
  setPosition: (toPosition, accuracy, silent = false)->
    _this = this

    if @moveAnimationState_?
      fromPosition = @moveAnimationState_.current
      @moveAnimationState_ = null
    else
      fromPosition = @position

    if toPosition == fromPosition
      # 何もしない
      return

    if toPosition? and fromPosition?
      # 移動
      @moveAnimationState_ =
        start: new Date()
        from: fromPosition.slice()
        current: fromPosition.slice()
        to: toPosition.slice()
　　　　
        animate: (frameStateTime)->
          time = (frameStateTime - @start) / 2000

          if time <= 1
            @current[0] = @from[0] + ((@to[0] - @from[0]) * ol.easing.easeOut(time))
            @current[1] = @from[1] + ((@to[1] - @from[1]) * ol.easing.easeOut(time))
            return true
          else
            _this.moveAnimationState_ = null # アニメーションが終わると消滅する
            return false

    else if toPosition?
      # 表示
      if @fadeInOutAnimationState_?
        from = @fadeInOutAnimationState_.current
      else
        from = 0
      @fadeInOutAnimationState_ =
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
            _this.fadeInOutAnimationState_ = null # アニメーションが終わると消滅する
            return false

    else
      # 非表示
      if @fadeInOutAnimationState_?
        from = @fadeInOutAnimationState_.current
      else
        from = 1
      @fadeInOutAnimationState_ =
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
            _this.fadeInOutAnimationState_ = null # アニメーションが終わると消滅する
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
    if @accuracyAnimationState_?
      from = @accuracyAnimationState_.current
      @accuracyAnimationState_ = null
    else
      from = @accuracy

    @accuracyAnimationState_ =
      start: new Date()
      from: from
      current: from

      animate: (frameStateTime)->
        time = (frameStateTime - @start) / 2000

        if time <= 1
          @current = @from + ((_this.accuracy - @from) * ol.easing.easeOut(time))
          return true
        else
          _this.accuracyAnimationState_ = null # アニメーションが終わると消滅する
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
    @directionAnimationState_ =
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
          _this.directionAnimationState_ = null # アニメーションが終わると消滅する
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
    if @moveAnimationState_? and @moveAnimationState_.animate(frameState.time)
      position = @moveAnimationState_.current
      frameState.animate = true # アニメーションを続ける

    # 回転アニメーション
    if @directionAnimationState_? and @directionAnimationState_.animate(frameState.time)
      direction = @directionAnimationState_.current
      frameState.animate = true # アニメーションを続ける

    # 表示/非表示アニメーション
    if @fadeInOutAnimationState_? and @fadeInOutAnimationState_.animate(frameState.time)
      opacity = @fadeInOutAnimationState_.current
      position = @fadeInOutAnimationState_.animationPosition
      frameState.animate = true # アニメーションを続ける

    # 円アニメーション
    if @accuracyAnimationState_? and @accuracyAnimationState_.animate(frameState.time)
      # アニメーション中
      accuracy = @accuracyAnimationState_.current
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

    $('#debug').text(JSON.stringify(
      '現在地ステータス': kanimarker.position
      '回転': kanimarker.direction
      '円のサイズ': kanimarker.accuracy
      '表示/非表示': `(kanimarker.position != null) ? '表示' : '非表示'`
      '表示モード': `kanimarker.headingUp ? '追従モード' : 'ビューモード'`
      '移動中': `(kanimarker.moveAnimationState_ != null) ? 'アニメーション中' : 'アニメーションなし'`
      '回転中': `(kanimarker.directionAnimationState_ != null) ? 'アニメーション中' : 'アニメーションなし'`
      '円の拡大/縮小': `(kanimarker.accuracyAnimationState_ != null) ? 'アニメーション中' : 'アニメーションなし'`
      '表示/非表示': `(kanimarker.fadeInOutAnimationState_ != null) ? 'アニメーション中' : 'アニメーションなし'`
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
        if @moveAnimationState_?
          if @moveAnimationState_.animate(frameState.time)
            position = @moveAnimationState_.current
          else
            # ラスト1回はView本体の中心を上書き(renderを呼び続けないための対策)
            @map.getView().setCenter(@position.slice())

        # 回転アニメーション
        if @directionAnimationState_?
          if @directionAnimationState_.animate(frameState.time)
            direction = @directionAnimationState_.current
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
