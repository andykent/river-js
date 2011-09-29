events = require("events")
{BaseStage} = require('./base')

exports.Output = class Output extends events.EventEmitter

  push: (data) ->
    @emit('update', [data], null)
  