events = require("events")
{BaseStage} = require('./base')

exports.Output = class Output extends events.EventEmitter

  push: (newValues, oldValues=null) ->
    @emit('insert', newValues) if newValues
    @emit('remove', oldValues) if oldValues