{BaseStage} = require('./base')

exports.Store = class Store extends BaseStage

  constructor: (tableDef) ->
    @name = tableDef.name.value
    @window = tableDef.win
    @limitBy = tableDef.winFn
    @limitValue = tableDef.winArg.value
    @db = []
  push: (data) ->
    @db.push(data)
    if @db.length > @limitValue
      old = @db.shift()
    old = if old then [old] else null
    @emit('insert', data)
    @emit('remove', old)