{BaseStage} = require('./base')

exports.Repeater = class Store extends BaseStage

  constructor: (tableDef) ->
    @name = tableDef.name.value
    @window = tableDef.win
    @limitBy = tableDef.winFn
    @limitValue = tableDef.winArg.value
    @db = []
    
  insert: (data) ->
    @db.push(data)
    if @db.length > @limitValue
      old = @db.shift()
    if old
      @emit('insert-remove', data, old)
    else
      @emit('insert', data)
