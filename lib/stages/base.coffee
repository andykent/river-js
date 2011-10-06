events = require("events")

exports.BaseStage = class BaseStage extends events.EventEmitter

  pass: (nextStage) ->
    @nextStage = nextStage
    @on('insert', (data) => @nextStage.insert(data))
    @on('remove', (data) => @nextStage.remove(data))
    nextStage
  
  insert: (data) ->
    @emit('insert', data)
  
  remove: (data) ->
    @emit('remove', data)
    