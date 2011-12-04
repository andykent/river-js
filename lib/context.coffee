{Query} = require('./query')
{StreamManager} = require('./stream_manager')

# Context
# -------
# Everything in River happens within a context.
# You can consider it a container much like a DataBase in an RDBMS.
exports.Context = class Context
  
  constructor: ->
    @queryIdCounter = 1
    @queries = {}
    @streamManager = new StreamManager()
  
  # A convenience function for creating a new `Query` and
  # registering it with the `SteamManager` for this context
  # If you pass a function as a second argument then this gets
  # bound to the insert stream of the newly created `Query`.
  addQuery: (queryString, insertCallback=null) ->
    query = new Query(queryString)
    if existingQuery = @get(query.id)
      query.destroy
      return existingQuery
    query.on('insert', insertCallback) if insertCallback
    query.start(@streamManager)
    @queries[query.id] = query
    query
  
  # Given an queryId, we shut it down and then
  # remove it from the pool.
  removeQuery: (id) ->
    query = @get(id)
    return false unless query
    id = query.id
    query.destroy()
    delete @queries[id]
    true
  
  # Given either a query or a queryId, return either the query or null.
  get: (queryOrId) ->
    id = if queryOrId and queryOrId.constructor is Query
      queryOrId.id 
    else 
      queryOrId
    @queries[id] or null
  
  # A convenience function for pushing new data into a stream
  # within this context. This is the prefered way to insert data unless
  # you need direct access to the `StreamManager` for some reason.
  push: (streamName, data) ->
    @streamManager.fetch(streamName).push(data)
    true
  