events = require("events")
stages = require('./stages')
nodes = require('sql-parser').nodes
{Field} = require('./field')


exports.QueryPlan = class QueryPlan extends events.EventEmitter
  constructor: (query) ->
    @query = query
    @build()
  
  start: (streamManager) ->
    listener = new stages.Listen(streamManager, @query.source.name.value)
    listener.on 'data', (data) => @root.insert(data)
  
  build: ->
    @fields = Field.fieldListFromNodes(@query.fields, @isWindowed())
    @root = new stages.Root()
    @lastStage = @root
    @addRepeater() if @isWindowed()
    @addFilter() if @query.where
    if @hasAggregation() then @addAggregation() else @addProjection()
    @addDistinct() if @query.distinct
    @addLimit() if @query.limit
    # OUTPUT stage
    output = new stages.Output()
    output.on 'insert', (newValues) => @emit('insert', newValues)
    output.on 'remove', (oldValues) => @emit('remove', oldValues)
    @lastStage.pass(output)

  addRepeater: ->
    if @query.source.winFn is 'length'
      repeater = new stages.LengthRepeater(@query.source)
    else
      repeater = new stages.TimeRepeater(@query.source)
    @lastStage = @lastStage.pass(repeater)
  
  addFilter: ->
    filter = new stages.Filter(@query.where.conditions)
    @lastStage = @lastStage.pass(filter)
    
  addAggregation: ->
    if @query.group
      store = new stages.Aggregation(@fields, @query.group.fields, @query.group.having)
    else
      store = new stages.Aggregation(@fields)
    @lastStage = @lastStage.pass(store)

  addProjection: ->    
    projection = new stages.Projection(@fields)
    @lastStage = @lastStage.pass(projection)
    
  addDistinct: ->
    distinct = new stages.Distinct()
    @lastStage = @lastStage.pass(distinct)
    
  addLimit: ->
    limit = new stages.Limit(@query.limit.value)
    @lastStage = @lastStage.pass(limit)
    
  aggregatorFields: ->
    (f for f in @query.fields when f.field? and f.field.constructor is nodes.FunctionValue and !f.field.udf)
  
  hasAggregation: ->
    @aggregatorFields().length > 0
  
  isWindowed: -> @query.source.win isnt null