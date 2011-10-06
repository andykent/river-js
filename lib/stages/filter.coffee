{ConditionCompiler} = require('./../condition_compiler')
{BaseStage} = require('./base')


exports.Filter = class Filter extends BaseStage

  constructor: (@conditions) ->
    @compiledConditions = new ConditionCompiler(@conditions)
    
  push: (data) ->
    @emit('insert', data) if @compiledConditions.exec(data)