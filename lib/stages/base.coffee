exports.BaseStage = class BaseStage

  pass: (nextStage) ->
    @nextStage = nextStage
    nextStage
  
  push: (data) ->
    @nextStage.push(data)