events = require("events")

exports.BaseStage = class BaseStage extends events.EventEmitter

  pass: (nextStage) ->
    @nextStage = nextStage
    @on('insert', (data) => @nextStage.push(data))
    nextStage
  
  push: (data) ->
    @nextStage.push(data)