assert = require('assert')
should = require('should')
Kanimarker = require('../kanimarker')

describe 'Kanimarker', ->
  it 'No error on initialize', (done)->
    Kanimarker(null)
    done()
  it 'Should 0 -> 0 = 0', (done)->
    x = Kanimarker(null)
    done()

