var gulp = require('gulp');
var coffee = require('gulp-coffee');
var gutil = require('gulp-util');
var codo = require('gulp-codo');

gulp.task('default', function () {
    gulp.src('kanimarker.coffee')
        .pipe(coffee({bare: true}).on('error', gutil.log))
        .pipe(gulp.dest('./')
    );
    gulp.src('kanimarker.coffee')
        .pipe(codo({
            name: 'Kanimarker',
            title: 'Position Marker for OpenLayers3',
            readme: 'README.md'
        })
    );
});
