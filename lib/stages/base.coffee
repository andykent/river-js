events = require("events")

exports.BaseStage = class BaseStage extends events.EventEmitter

  constructor: (@context) -> null
  
  pass: (nextStage) ->
    @nextStage = nextStage
    @on('insert', (data) => @nextStage.insert(data))
    @on('remove', (data) => @nextStage.remove(data))
    @on('insert-remove', (i,r) => @nextStage.insertRemove(i,r))
    nextStage
  
  insert: (data) ->
    @emit('insert', data)
  
  remove: (data) ->
    @emit('remove', data)

  insertRemove: (i,r) ->
    @emit('insert-remove', i, r)
    