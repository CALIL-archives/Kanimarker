# Kanimarker

> **⚠️ このリポジトリはアーカイブされています**
>
> 配信に使っていた Amazon S3 バケットは既に削除されており、旧 URL は
> 第三者が同名バケットを作成して任意のコードを配信できる状態でした。
> このためデモ・ドキュメント・CDN のリンクを削除しています。
> 動かす場合はこのリポジトリをクローンしてローカルで開いてください。

このプロジェクトは[さばとマップ](https://github.com/CALIL/sabatomap)に統合されました

`Kanimarker` is "self-position" marker library for [OpenLayers 3](https://openlayers.org/). <br>
Draw marker(GPS or other any locations) and manage animations for heading-up mode.<br>
Easy install and integration with OpenLayers 3.

`Kanimarker` は [OpenLayers 3](https://openlayers.org/) で動作する現在地表示ライブラリです。
GPSやその他の様々なロケーション（現在地）を表示するとともに、ヘディングアップモードや追従モードなどの
ナビゲーションで標準的に必要とされるアニメーションを管理します。OpenLayers 3に簡単にインストールして連携できます。

## Usage

This is simple use-case.

```javascript
var map = new ol.Map({ ... });
kanimarker = new Kanimarker(map);
kanimarker.setPosition([137.528032,35.573162],50);
```

## Examples

ホスティングを終了しました。リポジトリ内の `examples/demo.html` /
`examples/geolocation.html` をローカルで開いてください。

## Document

リポジトリ内の `doc/class/Kanimarker.html` を参照してください。

## CDN

CDN での配信は終了しました。`kanimarker.js` をリポジトリから取得してください。

## License

This software is released under the MIT License.

Copyright (C) 2015 CALIL Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without lmitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.