gulp = require('gulp')
browserify = require('browserify')
source = require('vinyl-source-stream')
codo = require('gulp-codo')

gulp.task 'default', ->
  return browserify('./kanimarker.es2015.js')
    .transform('babelify', {presets: ['es2015']})
    .bundle()
    .pipe(source('kanimarker.js'))
    .pipe(gulp.dest('./'));

gulp.task 'codo', ->
  return  gulp.src('kanimarker.coffee').pipe codo(
    name: 'Kanimarker'
    title: 'Position Marker for OpenLayers3'
    readme: 'README.md')
