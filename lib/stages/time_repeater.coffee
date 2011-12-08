{BaseStage} = require('./base')

exports.TimeRepeater = class TimeRepeater extends BaseStage

  constructor: (@context, tableDef) ->
    @name = tableDef.name.value
    @window = tableDef.win
    @limitBy = tableDef.winFn
    @delayValue = tableDef.winArg.value * 1000
    
  insert: (data) ->
    setTimeout (=> @emit('remove', data)), @delayValue
    @emit('insert', data)
