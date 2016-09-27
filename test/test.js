var Kanimarker, assert, should;

// assert = require('assert');

// should = require('should');

// Kanimarker = require('../kanimarker');

describe('Kanimarker', function() {
  it('No error on initialize', function(done) {
    Kanimarker(null);
    return done();
  });
  return it('Should 0 -> 0 = 0', function(done) {
    var x;
    x = Kanimarker(null);
    return done();
  });
});