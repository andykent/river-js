events = require("events")
{BaseStage} = require('./base')

exports.Output = class Output extends events.EventEmitter

  insert: (newValues) ->
    @emit('insert', newValues) if newValues
  
  remove: (oldValues) ->
    @emit('remove', oldValues) if oldValues