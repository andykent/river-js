support = require('./../../support')

class Sum

  constructor: (@args) ->
    @count = 0
    throw new Error("SUM() should only be called with one argument") unless @args.length is 1
    @field = @args[0]
    
  insert: (record) ->
    oldCount = @count
    val = @field.exec(record)
    val = Number(val) unless typeof val is 'number'
    @count += val
    @count unless @count is oldCount
  
  remove: (record) ->
    oldCount = @count
    val = @field.exec(record)
    val = Number(val) unless typeof val is 'number'
    @count -= val
    @count unless @count is oldCount
  
exports.fn = Sum