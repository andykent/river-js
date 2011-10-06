parser = require('sql-parser')
events = require("events")
{QueryPlan} = require('./query_plan')

queryIdCounter = 1

exports.Query = class Query extends events.EventEmitter
  constructor: (sqlString) ->
    @sqlString = sqlString
    @parsedQuery = parser.parse(@sqlString)
    @id = queryIdCounter++
    @compiledQuery = new QueryPlan(@parsedQuery)
  start: (streamManager) ->
    @compiledQuery.on 'insert', (newValues) => @emit('insert', newValues)
    @compiledQuery.on 'remove', (oldValues) => @emit('remove', oldValues)
    @compiledQuery.start(streamManager)
  toString: -> @parsedQuery.toString()


