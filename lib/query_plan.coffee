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
    @build()
  
  # Call start with a `StreamManager` to hook up
  # a `Listen` stage to push new data into the the
  # `Root` stage of this `QueryPlan`.
  start: (streamManager) ->
    listener = new stages.Listen(streamManager, @query.source.name.value)
    listener.on 'data', (data) => @root.insert(data)
  
  # This is the real meat of River, here we decide what stages a 
  # query needs to go through to produce the required output.
  #
  # Breaking qeueries down into stages with events flowing between them
  # is a nice way to break a complex problem down into simple steps.
  #
  # Stages get bound together as a chain of events `@lastStage` is
  # used to track where the tail of this chain is so we can easily add
  # more Stages to the end of a plan.
  build: ->
    @fields = Field.fieldListFromNodes(@query.fields, @isWindowed())
    @root = new stages.Root()
    @lastStage = @root
    @addMinifier()
    @addRepeater() if @isWindowed()
    @addFilter() if @query.where
    if @hasAggregation() then @addAggregation() else @addProjection()
    @addDistinct() if @query.distinct
    @addLimit() if @query.limit
    # The output stage is a specal case which bubbles the final events up to the `Query`
    output = new stages.Output()
    output.on 'insert', (newValues) => @emit('insert', newValues)
    output.on 'remove', (oldValues) => @emit('remove', oldValues)
    @lastStage.pass(output)
  
  # Minifiers take the insert stream and strip out fields
  # that aren't needed by the query.
  addMinifier: ->
    minifier = new stages.Minifier(@query)
    @lastStage = @lastStage.pass(minifier)
  
  # Repeaters only get used when the `Query` is windowed.
  # They take the insert stream, stash it away, and then 
  # replay it on the remove stream once the conditions are met.
  addRepeater: ->
    if @query.source.winFn is 'length'
      repeater = new stages.LengthRepeater(@query.source)
    else
      repeater = new stages.TimeRepeater(@query.source)
    @lastStage = @lastStage.pass(repeater)
  
  # Filters handle the WHERE part of a query.
  # They compile the conditions and then only emit
  # on events that meet the conditions.
  addFilter: ->
    filter = new stages.Filter(@query.where.conditions)
    @lastStage = @lastStage.pass(filter)
  
  # Aggregations take care of GROUP clauses and Agg Functions
  # like `COUNT`.
  # They collect and track the aggregations but only emit when
  # changes to computed values occur.
  addAggregation: ->
    store = new stages.Aggregation(@fields, @query.group?.fields, @query.group?.having)
    @lastStage = @lastStage.pass(store)
  
  # Projections take a set of `Field` expressions and emit new
  # objects that contain the correctly computed and named values
  addProjection: ->    
    projection = new stages.Projection(@fields)
    @lastStage = @lastStage.pass(projection)
  
  # Distincts take injest and insert stream and only
  # emit when a record that hasn't been seen before is found
  addDistinct: ->
    distinct = new stages.Distinct()
    @lastStage = @lastStage.pass(distinct)
  
  # Limits only really make sense on non-windowed queries they stop
  # emitting insert events once the limit number has been reached.
  addLimit: ->
    limit = new stages.Limit(@query.limit.value)
    @lastStage = @lastStage.pass(limit)
  
  # Lists the fields that are aggregators.
  aggregatorFields: -> (f for f in @fields when f.isFunction() and !f.isUDF())
  
  # Returns true if any of the Fields are aggregations.
  hasAggregation: -> @aggregatorFields().length > 0
  
  # Returns true if the query runs over a window of any kind.
  isWindowed: -> @query.source.win isnt null
  