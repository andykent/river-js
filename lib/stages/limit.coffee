{BaseStage} = require('./base')

exports.Limit = class Limit extends BaseStage

  constructor: (@context, limit) ->
    @limit = limit.value
    @passed = 0
  
  insert: (data) ->
    return if @limit == @passed
    @passed++
    @emit('insert', data) 