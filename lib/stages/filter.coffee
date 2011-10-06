{ConditionCompiler} = require('./../condition_compiler')
{BaseStage} = require('./base')


exports.Filter = class Filter extends BaseStage

  constructor: (@conditions) ->
    @compiledConditions = new ConditionCompiler(@conditions)
    
  insert: (data) ->
    @emit('insert', data) if @compiledConditions.exec(data)
    
  remove: (data) ->
    @emit('remove', data) if @compiledConditions.exec(data)
    
  insertRemove: (i,r) ->
    iPass = @compiledConditions.exec(i)
    rPass = @compiledConditions.exec(r)
    if iPass and rPass
      @emit('insert-remove', i, r)
    else
      @emit('insert', i) if iPass
      @emit('remove', r) if rPass
    