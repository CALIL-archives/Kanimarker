var gulp = require('gulp');
var browserify = require('browserify');
var source = require('vinyl-source-stream');

gulp.task('default', function () {
  return browserify('./kanimarker.es2015.js')
    .transform('babelify', {presets: ['es2015']})
    .bundle()
    .pipe(source('kanimarker.js'))
    .pipe(gulp.dest('./'));
});
