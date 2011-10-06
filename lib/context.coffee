{Query} = require('./query')
{StreamManager} = require('./stream_manager')

exports.Context = class Context
  constructor: ->
    @queryIdCounter = 1
    @queries = []
    @streamManager = new StreamManager()
  addQuery: (queryString, insertCallback=null) ->
    query = new Query(queryString)
    query.on('insert', insertCallback) if insertCallback
    query.start(@streamManager)
    @queries.push(query)
    query
  push: (streamName, data) ->
    @streamManager.fetch(streamName).push(data)
    true
  