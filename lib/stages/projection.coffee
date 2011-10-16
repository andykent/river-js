{BaseStage} = require('./base')
functions = require('./../functions')
aggregates = require('./../aggregates')
nodes = require('sql-parser').nodes
{ExpressionCompiler} = require('./../expression_compiler')
{Field} = require('./../field')


exports.Projection = class Projection extends BaseStage

  constructor: (@fields) ->
    @mode = null
    @hasAggregation = @fields.some((f) -> f.isAggregate())
    @aggDataChange = false
  
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
    return projectedData if @hasAggregation is false
    return null if @aggDataChange is false
    @aggDataChange = false
    projectedData      
    
  isStarQuery: -> 
    @fields.length is 1 and @fields[0].star
    
  extractFieldsFromRecord: (record) ->
    return record if @isStarQuery()
    ret = {}
    for field in @fields
      ret[field.name] = @fieldValue(field, record)
    ret
  
  fieldValue: (field, record) ->
    val = field.perform(@mode, record)
    @aggDataChange = true if @hasAggregation and val?
    val
  