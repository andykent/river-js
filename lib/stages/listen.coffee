events = require("events")
{BaseStage} = require('./base')
uuid = require('node-uuid')

exports.Listen = class Listen extends events.EventEmitter
  constructor: (streamManager, @sourceName) ->
    streamManager.fetch(@sourceName).on('data', (data) => @emit('data', @withMetadata(data)))
  
  withMetadata: (data) ->
    data._ = 
      uuid: uuid.v4()
      src:  @sourceName
      ts:   new Date()    
    data