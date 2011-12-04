events = require("events")
{BaseStage} = require('./base')
uuid = require('node-uuid')

exports.Listen = class Listen extends events.EventEmitter
  constructor: (@streamManager, @sourceName) ->
    @listenFn = ((data) => @emit('data', @withMetadata(data)))
    @streamManager.fetch(@sourceName).on('data', @listenFn)
  
  withMetadata: (data) ->
    data._ = 
      uuid: uuid.v4()
      src:  @sourceName
      ts:   new Date()    
    data
    
  stop: ->
    @streamManager.fetch(@sourceName).removeListener('data', @listenFn)