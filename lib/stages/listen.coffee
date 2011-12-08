events = require("events")
{BaseStage} = require('./base')
uuid = require('node-uuid')

exports.Listen = class Listen extends events.EventEmitter
  constructor: (@context, @sourceName) ->
    @listenFn = ((data) => @emit('data', @withMetadata(data)))
    @context.streamManager.fetch(@sourceName).on('data', @listenFn)
  
  withMetadata: (data) ->
    data._ = 
      uuid: uuid.v4()
      src:  @sourceName
      ts:   new Date()    
    data
    
  stop: ->
    @context.streamManager.fetch(@sourceName).removeListener('data', @listenFn)