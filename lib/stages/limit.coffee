{BaseStage} = require('./base')

exports.Limit = class Limit extends BaseStage

  constructor: (limit) ->
    @limit = limit.value
    @passed = 0
  
  push: (data) ->
    return if @limit == @passed
    @passed++
    @emit('insert', data) 