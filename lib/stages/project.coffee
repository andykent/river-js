{BaseStage} = require('./base')
functions = require('./../functions')
nodes = require('sql-parser').nodes


exports.Project = class Project extends BaseStage

  constructor: (fields) ->
    @fields = fields
    @initFunctions()
  
  push: (data) ->
    projectedData = @extractFieldsFromRecord(data)
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
      fn.push(record)
    else
      record[field.field.value]
  
  fieldIsFunction: (field) -> 
    field? and field.constructor is nodes.FunctionValue
  
  initFunctions: () ->
    @functions = {}
    for field in @fields when @fieldIsFunction(field.field)
      klass = functions.get(field.field.name)
      instance = new klass(field.field.arguments)
      @functions[@fieldName(field)] = instance
      
      
      
      