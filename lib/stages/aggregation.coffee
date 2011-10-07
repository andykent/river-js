{BaseStage} = require('./base')
aggregates = require('./../aggregates')
nodes = require('sql-parser').nodes


exports.Aggregation = class Store extends BaseStage

  constructor: (fields) ->
    @fields = fields
    @storedRecord = null
    @buildAggregators()

  insert: (record) ->
    @run('insert', record)
  
  remove: (data) ->
    @run('remove', record)
  
  insertRemove: (i, r) ->
    @run('insertRemove', i, r)
    
  run: (mode, record, record2) ->
    oldRecord = @storedRecord
    if mode is 'insertRemove'
      @aggregate('remove', record2)
      @storedRecord = @aggregate('insert', record)
    else
      @storedRecord = @aggregate(mode, record)
    if @recordsDiffer(@storedRecord, oldRecord)
      @emit('remove', oldRecord) if oldRecord?
      @emit('insert', @storedRecord)
  
  aggregate: (mode, record) ->
    result = {}
    for field, agg of @fieldAggregators
      result[field] = agg[mode](record)
    result
  
  buildAggregators: ->
    @fieldAggregators = {}
    for field in @fields
      @fieldAggregators[@fieldName(field)] = @buildAggregator(field)
  
  buildAggregator: (field) ->
    if @fieldIsFunction(field.field)
      klass = aggregates.get(field.field.name)
      instance = new klass(field.field.arguments)
      instance
    else
      {
        insert: (record) -> record[field.field.value],
        remove: (record) -> record[field.field.value]
      }
  
  fieldName: (field) ->
    if @fieldIsFunction(field.field)
      field.name or field.toString()
    else
      field.name or field.field.value

  fieldIsFunction: (field) -> 
    field? and field.constructor is nodes.FunctionValue
  
  recordsDiffer: (a, b) ->
    JSON.stringify(a) isnt JSON.stringify(b)