events = require("events")
stages = require('./stages')
nodes = require('sql-parser').nodes

exports.QueryPlan = class QueryPlan extends events.EventEmitter
  constructor: (query) ->
    @query = query
    @build()
  
  start: (streamManager) ->
    listener = new stages.Listen(streamManager, @query.source.name.value)
    listener.on 'data', (data) => @root.insert(data)
  
  build: ->
    @root = new stages.Root()
    @lastStage = @root
    if @query.source.win
      @buildBounded()
    else
      @buildUnbounded()
    # OUTPUT stage
    output = new stages.Output()
    output.on 'insert', (newValues) => @emit('insert', newValues)
    output.on 'remove', (oldValues) => @emit('remove', oldValues)
    @lastStage.pass(output)

  buildUnbounded: ->
    # WHERE clause
    if @query.where
      filter = new stages.Filter(@query.where.conditions)
      @lastStage = @lastStage.pass(filter)
    
    # SELECT fields
    projection = new stages.Projection(@query.fields)
    @lastStage = @lastStage.pass(projection)
    
    # SELECT DISTINCT
    if @query.distinct
      distinct = new stages.Distinct()
      @lastStage = @lastStage.pass(distinct)
    
    # LIMIT size
    if @query.limit
      limit = new stages.Limit(@query.limit.value)
      @lastStage = @lastStage.pass(limit)
  
  buildBounded: ->
    # tell the data to replay based on the window
    if @query.source.winFn is 'length'
      repeater = new stages.LengthRepeater(@query.source)
    else
      repeater = new stages.TimeRepeater(@query.source)
    @lastStage = @lastStage.pass(repeater)

    # WHERE clause to pre filter
    if @query.where
      filter = new stages.Filter(@query.where.conditions)
      @lastStage = @lastStage.pass(filter)
    
    if @hasAggregation()
      # Do aggregation if needed
      if @query.group
        store = new stages.Aggregation(@query.fields, @query.group.fields)
      else
        store = new stages.Aggregation(@query.fields)
      @lastStage = @lastStage.pass(store)
    else    
      # SELECT fields
      projection = new stages.Projection(@query.fields)
      @lastStage = @lastStage.pass(projection)
  
  aggregatorFields: ->
    (f for f in @query.fields when f.field? and f.field.constructor is nodes.FunctionValue and !f.field.udf)
  
  hasAggregation: ->
    @aggregatorFields().length > 0
    