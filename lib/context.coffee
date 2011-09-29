{Query} = require('./query')
{StreamManager} = require('./stream_manager')

exports.Context = class Context
  constructor: ->
    @queryIdCounter = 1
    @queries = []
    @streamManager = new StreamManager()
  addQuery: (queryString, callback=(->)) ->
    query = new Query(queryString)
    query.on('update', callback)
    query.start(@streamManager)
    @queries.push(query)
    query.id
  push: (streamName, data) ->
    @streamManager.fetch(streamName).push(data)
    true
  