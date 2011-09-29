{ConditionCompiler} = require('./../condition_compiler')
{BaseStage} = require('./base')


exports.Filter = class Filter extends BaseStage

  constructor: (@conditions) ->
    @compiledConditions = new ConditionCompiler(@conditions)
    
  push: (data) ->
    @nextStage.push(data) if @compiledConditions.exec(data)