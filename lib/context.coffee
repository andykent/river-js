Query = require('./query').Query

exports.Context = class Context
  constructor: ->
    @queryIdCounter = 1
    @queries = []
  addQuery: (queryString, callback=(->)) ->
    query = new Query(queryString)
    query.on('update', callback)
    @queries.push(query)
    query.id
  push: (stream, data) ->
    query.push(stream, data) for query in @queries
    true
  