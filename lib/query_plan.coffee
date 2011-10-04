events = require("events")
stages = require('./stages')

exports.QueryPlan = class QueryPlan extends events.EventEmitter
  constructor: (query) ->
    @query = query
    @build()
  
  start: (streamManager) ->
    listener = new stages.Listen(streamManager, @query.source.name.value)
    listener.on 'data', (data) => @root.push(data)
  
  build: ->
    @root = new stages.Root()
    @lastStage = @root
    if @query.source.win
      @buildBounded()
    else
      @buildUnbounded()
    
  buildUnbounded: ->        
    # WHERE clause
    if @query.where
      filter = new stages.Filter(@query.where.conditions)
      @lastStage = @lastStage.pass(filter)
    
    # GROUP BY fields
    if @query.group
      group = new stages.Group(@query.group)
      @lastStage = @lastStage.pass(group)
    
    # SELECT fields
    projection = new stages.Project(@query.fields)
    @lastStage = @lastStage.pass(projection)
    
    # SELECT DISTINCT
    if @query.distinct
      distinct = new stages.Distinct()
      @lastStage = @lastStage.pass(distinct)
    
    # LIMIT size
    if @query.limit
      limit = new stages.Limit(@query.limit.value)
      @lastStage = @lastStage.pass(limit)
    
    # OUTPUT stage
    output = new stages.Output()
    output.on 'update', (newValues, oldValues) => @emit('update', newValues, oldValues)
    @lastStage.pass(output)
  
  buildBounded: ->
    

