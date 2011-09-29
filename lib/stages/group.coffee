{BaseStage} = require('./base')

exports.Group = class Group extends BaseStage

  constructor: (group) ->
    @fields = group.fields
    @groups = {}
  
  push: (data) ->
    key = @makeKey(data)
    @groups[key] = data
    @nextStage.push(data)
  
  makeKey: (record) ->
    ret = {}
    for field in @fields
      ret[field.value] = record[field.value]
    JSON.stringify(ret)
  