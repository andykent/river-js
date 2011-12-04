crypto = require('crypto')
parser = require('sql-parser')
events = require("events")
{QueryPlan} = require('./query_plan')


# Query
# -----
# Object that represents a query that exists within a `Context`
exports.Query = class Query extends events.EventEmitter
  
  # given a query string a new query object is contructed
  # first the SQL is parsed into a set of nodes which is
  # then used to construct a `QueryPlan`
  constructor: (sqlString) ->
    @sqlString = sqlString
    @parsedQuery = parser.parse(@sqlString)
    @id = @hash()
    @compiledQuery = new QueryPlan(@parsedQuery)
    
  # Calling `start` on a query registers it's event 
  # handlers to bubble stream events up and then
  # executes the compiled `QueryPlan` against a streamManager.
  start: (streamManager) ->
    @compiledQuery.on 'insert', (newValues) => @emit('insert', newValues)
    @compiledQuery.on 'remove', (oldValues) => @emit('remove', oldValues)
    @compiledQuery.start(streamManager)
    
  stop: ->    
    @compiledQuery.stop()
  
  # at the moment this just defers to stop() but
  # there maybe more teardown to be done in the future.
  destroy: ->
    @stop()
    true
  
  # It's nice to represent Query objects as the pretty formatted SQL
  # note, this is the interpreted SQL and not the original input query.
  toString: -> @parsedQuery.toString()
  
  hash: -> crypto.createHash('sha1').update(@parsedQuery.toString()).digest('hex')

