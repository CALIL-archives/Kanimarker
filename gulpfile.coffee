gulp = require('gulp')
coffee = require('gulp-coffee')
gutil = require('gulp-util')
codo = require('gulp-codo')

gulp.task 'default', [], ->
  return gulp.src('kanimarker.coffee').pipe(coffee(bare: true).on('error', gutil.log)).pipe gulp.dest('./')

gulp.task 'codo', ->
  return  gulp.src('kanimarker.coffee').pipe codo(
    name: 'Kanimarker'
    title: 'Position Marker for OpenLayers3'
    readme: 'README.md')
