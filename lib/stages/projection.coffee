{BaseStage} = require('./base')
functions = require('./../functions')
aggregates = require('./../aggregates')
nodes = require('sql-parser').nodes
{ExpressionCompiler} = require('./../expression_compiler')


exports.Projection = class Projection extends BaseStage

  constructor: (fields) ->
    @fields = fields
    @mode = null
    @hasAggregation = false
    @aggDataChange = false
    @initExpressions()
    @initFunctions()
  
  insert: (data) ->
    @mode = 'insert'
    projectedData = @project(data)
    @emit('insert', projectedData) if projectedData

  remove: (data) ->
    @mode = 'remove'
    projectedData = @project(data)
    @emit('remove', projectedData) if projectedData
    
  insertRemove: (i,r) ->
    @remove(r)
    @insert(i)
  
  project: (data) -> 
    @aggDataChange = false
    projectedData = @extractFieldsFromRecord(data)
    if @hasAggregation is false or @aggDataChange is true
      projectedData
    else
      null
    
  isStarQuery: -> 
    @fields.length is 1 and @fields[0].star
    
  extractFieldsFromRecord: (record) ->
    return record if @isStarQuery()
    ret = {}
    for field in @fields
      ret[@fieldName(field)] = @fieldValue(field, record)
    ret
  
  fieldName: (field) ->
    if @fieldIsFunction(field.field) or @fieldIsExpression(field.field)
      if field.name then field.name.value.toString() else field.toString()
    else
      if field.name then field.name.value.toString() else field.field.value
  
  fieldValue: (field, record) ->
    if @fieldIsFunction(field.field)
      fn = @functions[@fieldName(field)]
      if field.field.udf
        fn.apply(record, @buildFnArgs(field.field.arguments, record))
      else
        if @mode = 'insert'
          val = fn.insert(record)
        else
          val = fn.remove(record)
        @aggDataChange = true if val?
        val
    else if @fieldIsExpression(field.field)
      @expressions[@fieldName(field)].exec(record)
    else
      record[field.field.value]
  
  fieldIsFunction: (field) -> 
    field? and field.constructor is nodes.FunctionValue
  
  fieldIsExpression: (field) ->
    field? and field.constructor is nodes.Op
  
  initExpressions: () ->
    @expressions = {}
    for field in @fields when @fieldIsExpression(field.field)
      @expressions[@fieldName(field)] = new ExpressionCompiler(field.field) 
  
  initFunctions: () ->
    @functions = {}
    for field in @fields when @fieldIsFunction(field.field)
      if field.field.udf
        @functions[@fieldName(field)] = functions.get(field.field.name)
      else
        @hasAggregation = true
        klass = aggregates.get(field.field.name)
        instance = new klass(field.field.arguments)
        @functions[@fieldName(field)] = instance
      
      
  buildFnArgs: (args, record) ->
    fnArgs = []
    for arg in args
      switch arg.constructor 
        when nodes.NumberValue  then arg.value
        when nodes.LiteralValue then record[arg.value]
        else arg.value