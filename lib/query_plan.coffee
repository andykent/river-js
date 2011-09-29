ConditionCompiler = require('./condition_compiler').ConditionCompiler

exports.QueryPlan = class QueryPlan
  constructor: (query) ->
    @plan = new BasicSelect(query)
  exec: (stream, data) ->
    @plan.exec(stream, data)
  
class BasicSelect
  constructor: (query) ->
    @query = query
    @compiledWhereConditions = new ConditionCompiler(@query.where.conditions) if @query.where
    @limit = if @query.limit then @query.limit.value.value else null
    @emitCount = 0
  exec: (stream, record) ->
    return @noDataResponse() if @limitReached()
    return @noDataResponse() unless @queryHasInterestInStream(stream)
    requestedFields = @extractFieldsFromRecord(record)
    if @checkConditions(requestedFields)
      @response([requestedFields], null)
    else
      @noDataResponse()
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
    @compiledWhereConditions.exec(record)
  limitReached: ->
    @emitCount is @limit
  noDataResponse: -> [null, null]
  response: (newValues, oldValues) ->
    @emitCount += newValues.length
    [newValues, oldValues]
