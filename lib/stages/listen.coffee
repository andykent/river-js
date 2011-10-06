events = require("events")
{BaseStage} = require('./base')

exports.Listen = class Listen extends events.EventEmitter
  constructor: (streamManager, sourceName) ->
    streamManager.fetch(sourceName).on('data', (data) => @emit('data', data))
