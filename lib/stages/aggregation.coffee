{BaseStage} = require('./base')
aggregates = require('./../aggregates')
functions = require('./../functions')
nodes = require('sql-parser').nodes


exports.Aggregation = class Store extends BaseStage

  constructor: (@fields, @groupFields=null) ->
    @grouped = true if @groupFields?
    @storedRecords = {}
    @groupAggregators = {}
  
  insert: (record) ->
    @run('insert', record)
  
  remove: (record) ->
    @run('remove', record)
  
  insertRemove: (i, r) ->
    @run('insertRemove', i, r)
    
  run: (mode, record, record2) ->
    key = @makeKey(record)
    oldRecord = @storedRecords[key]
    if mode is 'insertRemove'
      key2 = @makeKey(record2)
      oldRecord2 = @storedRecords[key2]
      @storedRecords[key2] = @aggregate('remove', key2, record2)
      @storedRecords[key]  = @aggregate('insert', key, record)
      if key isnt key2
        if @recordsDiffer(@storedRecords[key2], oldRecord2)
          @emit('remove', oldRecord2) if oldRecord2?
          @emit('insert', @storedRecords[key2])
    else
      @storedRecords[key] = @aggregate(mode, key, record)
    if @recordsDiffer(@storedRecords[key], oldRecord)
      @emit('remove', oldRecord) if oldRecord?
      @emit('insert', @storedRecords[key])
  
  aggregate: (mode, key, record) ->
    result = {}
    for field, agg of @getAggregators(key, record)
      result[field] = agg[mode](record)
    result
    
  getAggregators: (key, record) ->
    @groupAggregators[key] ?= @buildAggregators()
    # console.log(@groupAggregators)
    @groupAggregators[key]
  
  buildAggregators: ->
    a = {}
    for field in @fields
      a[@fieldName(field)] = @buildAggregator(field)
    a
  
  buildAggregator: (field) ->
    if @fieldIsFunction(field.field)
      if field.field.udf
        fn = functions.get(field.field.name)
        {
          insert: (record) => fn.apply(record, @buildFnArgs(field.field.arguments, record)),
          remove: (record) => fn.apply(record, @buildFnArgs(field.field.arguments, record))
        }        
      else
        klass = aggregates.getWindowed(field.field.name)
        instance = new klass(field.field.arguments)
        instance
    else
      {
        insert: (record) -> record[field.field.value],
        remove: (record) -> record[field.field.value]
      }
  
  fieldName: (field) ->
    if @fieldIsFunction(field.field)
      if field.name then field.name.value.toString() else field.toString()
    else
      if field.name then field.name.value.toString() else field.field.value

  fieldIsFunction: (field) -> 
    field? and field.constructor is nodes.FunctionValue
  
  recordsDiffer: (a, b) ->
    JSON.stringify(a) isnt JSON.stringify(b)
  
  
  makeKey: (record) ->
    return '__DEFAULT__' unless @grouped
    ret = {}
    for field in @groupFields
      ret[field.value] = record[field.value]
    JSON.stringify(ret)

  buildFnArgs: (args, record) ->
    fnArgs = []
    for arg in args
      switch arg.constructor 
        when nodes.NumberValue  then arg.value
        when nodes.LiteralValue then record[arg.value]
        else arg.value