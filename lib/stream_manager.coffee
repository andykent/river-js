events = require("events")

class Stream extends events.EventEmitter
  constructor: (name) ->
    @name = name
  push: (data) ->
    @emit('data', data)


exports.StreamManager = class StreamManager
  constructor: ->
    @streams = []
  create: (name) -> 
    @streams[name] = new Stream(name)
    @streams[name]
  
  fetch: (name) -> 
    @streams[name] or 
    @create(name)