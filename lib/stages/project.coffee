{BaseStage} = require('./base')

exports.Project = class Project extends BaseStage

  constructor: (fields) ->
    @fields = fields
  
  push: (data) ->
    projectedData = @extractFieldsFromRecord(data)
    @nextStage.push(projectedData)
    
  isStarQuery: -> 
    @fields.length is 1 and @fields[0].star
    
  extractFieldsFromRecord: (record) ->
    return record if @isStarQuery()
    ret = {}
    for field in @fields
      ret[field.name or field.field.value] = record[field.field.value]
    ret
  