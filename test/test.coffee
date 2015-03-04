# build time tests for morseteacher plugin
# see http://mochajs.org/

morseteacher = require '../client/morseteacher'
expect = require 'expect.js'

describe 'morseteacher plugin', ->

  describe 'expand', ->

    # it 'can make itallic', ->
    #   result = morseteacher.expand 'hello *world*'
    #   expect(result).to.be 'hello <i>world</i>'
