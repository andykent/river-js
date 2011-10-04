{BaseStage} = require('./base')
functions = require('./../functions')
aggregates = require('./../aggregates')
nodes = require('sql-parser').nodes


exports.Project = class Project extends BaseStage

  constructor: (fields) ->
    @fields = fields
    @hasAggregation = false
    @aggDataChange = false
    @initFunctions()
  
  push: (data) ->
    @aggDataChange = false
    projectedData = @extractFieldsFromRecord(data)
    if @hasAggregation is false or @aggDataChange is true
      @nextStage.push(projectedData)
    
  isStarQuery: -> 
    @fields.length is 1 and @fields[0].star
    
  extractFieldsFromRecord: (record) ->
    return record if @isStarQuery()
    ret = {}
    for field in @fields
      ret[@fieldName(field)] = @fieldValue(field, record)
    ret
  
  fieldName: (field) ->
    if @fieldIsFunction(field.field)
      field.name or field.toString()
    else
      field.name or field.field.value
  
  fieldValue: (field, record) ->
    if @fieldIsFunction(field.field)
      fn = @functions[@fieldName(field)]
      if field.field.udf
        fn.apply(record, @buildFnArgs(field.field.arguments, record))
      else
        val = fn.push(record)
        @aggDataChange = true if val?
        val
    else
      record[field.field.value]
  
  fieldIsFunction: (field) -> 
    field? and field.constructor is nodes.FunctionValue
  
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