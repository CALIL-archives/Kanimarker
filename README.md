# Kanimarker

[![Circle CI](https://circleci.com/gh/CALIL/Kanimarker/tree/master.svg?style=svg)](https://circleci.com/gh/CALIL/Kanimarker/tree/master)
[![Code Climate](https://codeclimate.com/github/CALIL/Kanimarker/badges/gpa.svg)](https://codeclimate.com/github/CALIL/Kanimarker)

`Kanimarker` is "self-position" marker library for [OpenLayers 3](http://openlayers.org/). <br>
Draw marker(GPS or other any locations) and manage animations for heading-up mode.<br>
Easy install and integration with OpenLayers 3.

`Kanimarker` は [OpenLayers 3](http://openlayers.org/) で動作する現在地表示ライブラリです。
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

- [Full control demo](https://s3-ap-northeast-1.amazonaws.com/kanimarker/examples/demo.html)

## Document

- [Kanimarker Class](https://s3-ap-northeast-1.amazonaws.com/kanimarker/doc/class/Kanimarker.html)

## [CDN](https://s3-ap-northeast-1.amazonaws.com/kanimarker/kanimarker.js)

## License

This software is released under the MIT License.

Copyright (C) 2015 CALIL Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
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