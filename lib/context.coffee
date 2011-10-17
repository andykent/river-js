{Query} = require('./query')
{StreamManager} = require('./stream_manager')

# Context
# -------
# Everything in River happens within a context.
# You can consider it a container much like a DataBase in an RDBMS.
exports.Context = class Context
  
  constructor: ->
    @queryIdCounter = 1
    @queries = []
    @streamManager = new StreamManager()
  
  # A convenience function for creating a new `Query` and
  # registering it with the `SteamManager` for this context
  # If you pass a function as a second argument then this gets
  # bound to the insert stream of the newly created `Query`.
  addQuery: (queryString, insertCallback=null) ->
    query = new Query(queryString)
    query.on('insert', insertCallback) if insertCallback
    query.start(@streamManager)
    @queries.push(query)
    query
  
  # A convenience function for pushing new data into a stream
  # within this context. This is the prefered way to insert data unless
  # you need direct access to the `StreamManager` for some reason.
  push: (streamName, data) ->
    @streamManager.fetch(streamName).push(data)
    true
  