events = require("events")

# Stream
# ------
# A `Stream` can be considered to be roughly equivelent
# to a table in RDBMS terms.
#
# River Streams are very primative at the moment and only
# know how to emit data events onto listeners.
class Stream extends events.EventEmitter
  constructor: (name) ->
    @name = name
  push: (data) ->
    @emit('data', data)


# StreamManager
# -------------
# Keeps track of several `Stream` Objects and lazily
# initializes them when a new one is requested.
exports.StreamManager = class StreamManager
  constructor: ->
    @streams = []
  
  # create a new `Stream` with the given name
  create: (name) -> 
    @streams[name] = new Stream(name)
    @streams[name]
  
  # fetch an existing `Stream` or create it if
  # it doesn't already exist.
  fetch: (name) -> 
    @streams[name] or 
    @create(name)