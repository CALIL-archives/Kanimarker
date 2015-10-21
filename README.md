# Kanimarker

[![Circle CI](https://circleci.com/gh/CALIL/Kanimarker/tree/master.svg?style=svg)](https://circleci.com/gh/CALIL/Kanimarker/tree/master)
[![Code Climate](https://codeclimate.com/github/CALIL/Kanimarker/badges/gpa.svg)](https://codeclimate.com/github/CALIL/Kanimarker)

Position Marker for OpenLayers3

## Hot to use

```javascript
    var map;
    map = new ol.Map({
        layers: [new ol.layer.Tile({
            source: new ol.source.XYZ({
                url: 'http://api.tiles.mapbox.com/v4/caliljp.ihofg5ie/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoiY2FsaWxqcCIsImEiOiJxZmNyWmdFIn0.hgdNoXE7D6i7SrEo6niG0w',
                maxZoom: 20
            })
        })],
        target: 'map',
        maxZoom: 26,
        minZoom: 18,
        logo: false,
        view: new ol.View({
            center: ol.proj.transform([137.528032, 35.573162], 'EPSG:4326', 'EPSG:3857'),
            zoom: 18
        })
    });

    kanimarker = new Kanimarker(map);

    function headingup_callback(isHeading) {
        console.log('headingup_callback:' + isHeading)
        if (isHeading == true) {
            document.getElementById("mhead").style.backgroundColor = "#ff5555";
        } else {
            document.getElementById("mhead").style.backgroundColor = "";
        }
    }
    kanimarker.on('change:headingup', headingup_callback);

    kanimarker.setPosition(ol.proj.transform([137.528032,35.573162], 'EPSG:4326', 'EPSG:3857'),50);
```

## Demo

https://s3-ap-northeast-1.amazonaws.com/kanimarker/demo.html

## Document

https://s3-ap-northeast-1.amazonaws.com/kanimarker/doc/class/Kanimarker.html

## Endpoint

https://s3-ap-northeast-1.amazonaws.com/kanimarker/kanimarker.js

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