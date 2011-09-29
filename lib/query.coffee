parser = require('sql-parser')
events = require("events")
QueryPlan = require('./query_plan').QueryPlan

queryIdCounter = 1

exports.Query = class Query extends events.EventEmitter
  constructor: (sqlString) ->
    @sqlString = sqlString
    @parsedQuery = parser.parse(@sqlString)
    @id = queryIdCounter++
    @compiledQuery = new QueryPlan(@parsedQuery)
  push: (stream, data) ->
    [newValues, oldValues] = @compiledQuery.exec(stream, data)
    @emit('update', newValues, oldValues) if newValues or oldValues


