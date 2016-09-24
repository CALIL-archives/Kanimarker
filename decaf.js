/**
 * ES2015移行スクリプト
 *
 * Created by sakai@calil.jp on 2016/09/24.
 */
var decaf = require('decafjs');
var fs = require('fs');

var raw = fs.readFileSync('kanimarker.coffee').toString();
var es2015 = decaf.compile(raw);
fs.writeFileSync('kanimarker.js', es2015);
