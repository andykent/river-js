{BaseStage} = require('./base')

exports.Distinct = class Distinct extends BaseStage

  constructor: (@context) ->
    @seen = []
  
  insert: (data) ->
    key = JSON.stringify(data)
    return if @seen.indexOf(key) > -1
    @seen.push(key)
    @emit('insert', data)