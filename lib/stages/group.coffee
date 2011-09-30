{BaseStage} = require('./base')

exports.Group = class Group extends BaseStage

  constructor: (group) ->
    @fields = group.fields
  
  push: (data) ->
    data['__bucket__'] = @makeKey(data)
    @nextStage.push(data)
  
  makeKey: (record) ->
    ret = {}
    for field in @fields
      ret[field.value] = record[field.value]
    JSON.stringify(ret)
  