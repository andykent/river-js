{BaseStage} = require('./base')

exports.Aggregation = class Store extends BaseStage

  constructor: (fields) ->
    @fields = fields
    @count = null    

  insert: (data) ->
    oldCount = @count
    @count += data.foo
    if oldCount isnt @count
      @emit('remove', {bar: oldCount}) if oldCount?
      @emit('insert', {bar: @count})
  
  remove: (data) ->
    oldCount = @count
    @count -= data.foo
    if oldCount? and oldCount isnt @count
      @emit('remove', {bar: oldCount}) if oldCount?
      @emit('insert', {bar: @count})
  
  insertRemove: (i, r) ->
    oldCount = @count
    @count += i.foo
    @count -= r.foo
    if oldCount? and oldCount isnt @count
      @emit('remove', {bar: oldCount}) if oldCount?
      @emit('insert', {bar: @count})