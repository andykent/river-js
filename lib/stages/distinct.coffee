{BaseStage} = require('./base')

exports.Distinct = class Distinct extends BaseStage

  constructor: ->
    @seen = []
  
  push: (data) ->
    key = JSON.stringify(data)
    return if @seen.indexOf(key)
    @seen.push(key)
    @nextStage.push(data)