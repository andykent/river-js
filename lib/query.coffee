parser = require('sql-parser')
events = require("events")

queryIdCounter = 1

exports.Query = class Query extends events.EventEmitter
  constructor: (sqlString) ->
    @sqlString = sqlString
    @parsedQuery = parser.parse(@sqlString)
    @id = queryIdCounter++
    @compiledQuery = queryCompiler(@parsedQuery)
  push: (stream, data) ->
    [newValues, oldValues] = @compiledQuery.push(stream, data)
    @emit('update', newValues, oldValues) if newValues or oldValues

queryCompiler = (query) ->
  new BasicSelect(query)
  
class BasicSelect
  constructor: (query) ->
    @query = query
  push: (stream, record) ->
    return [null, null] unless @queryHasInterestInStream(stream)
    requestedFields = @extractFieldsFromRecord(record)
    if @checkConditions(requestedFields)
      [[requestedFields], null]
    else
      [null,null]
  queryHasInterestInStream: (stream) -> @query.source.value is stream
  isStarQuery: -> @query.fields.length is 1 and @query.fields[0].star
  extractFieldsFromRecord: (record) ->
    return record if @isStarQuery()
    ret = {}
    for field in @query.fields
      ret[field.name or field.field.value] = record[field.field.value]
    ret
  checkConditions: (record) ->
    return true unless @query.where
    cc = new ConditionCompiler(@query.where.conditions)
    cc.exec(record)

class ConditionCompiler
  constructor: (@conditions) ->
    @compile(@conditions)
  exec: (context) ->
    @compiledConditions(context)
  compile: (condition) ->
    compiledString = @compileNode(condition)
    # console.log(compiledString)
    compiledFunction = new Function('c', "return #{compiledString}")
    @compiledConditions = compiledFunction
  
  compileNode: (condition) ->
    left = @convertOrCompile(condition.left)
    right = @convertOrCompile(condition.right)
    op = @conditionConversion(condition.operation)
    compiledString = ['(', left, op, right, ')'].join(' ')
    compiledString
  
  literalConversion: (node) ->
    if node.constructor is parser.nodes.LiteralValue
      "c['#{node.value}']"
    else
      node.value
      
  conditionConversion: (op) ->
    switch op
      when 'AND'  then '&&'
      when 'OR'   then '||'
      when '='    then '=='
      else
        op
  
  convertOrCompile: (node) ->
    if node.constructor is parser.nodes.Op
      @compileNode(node)
    else
      @literalConversion(node)



