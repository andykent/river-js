{ConditionCompiler} = require('./../condition_compiler')
{BaseStage} = require('./base')


exports.Filter = class Filter extends BaseStage

  constructor: (@conditions) ->
    @compiledConditions = new ConditionCompiler(@conditions)
    
  insert: (data) ->
    @emit('insert', data) if @compiledConditions.exec(data)
    
  remove: (data) ->
    @emit('remove', data) if @compiledConditions.exec(data)
    