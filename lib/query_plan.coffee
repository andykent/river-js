events = require("events")
stages = require('./stages')
nodes = require('sql-parser').nodes
{Field} = require('./field')

# QueryPlan
# ---------
# Query Plans are where a parsed query gets converted into actual code ready to process data
# Most of the logic of River gets constructed in here.
exports.QueryPlan = class QueryPlan extends events.EventEmitter
  
  # Create a `QueryPlan` by passing in a set of parsed query nodes.
  # The plan is built immediately on construction.
  constructor: (query) ->
    @query = query
  
  # Call start with a `StreamManager` to hook up
  # a `Listen` stage to push new data into the the
  # `Root` stage of this `QueryPlan`.
  start: (streamManager) ->
    @root = new stages.Select(@query, streamManager)
    @root.on 'insert', (newValues) => @emit('insert', newValues)
    @root.on 'remove', (oldValues) => @emit('remove', oldValues)  
    
  