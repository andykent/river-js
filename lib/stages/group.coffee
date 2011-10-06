{BaseStage} = require('./base')

exports.Group = class Group extends BaseStage

  constructor: (group) ->
    @groupingFields = group.fields
  
  insert: (data) ->
    data['__bucket__'] = @makeKey(data)
    @emit('insert', data)
  
  makeKey: (record) ->
    ret = {}
    for field in @groupingFields
      ret[field.value] = record[field.value]
    JSON.stringify(ret)
  