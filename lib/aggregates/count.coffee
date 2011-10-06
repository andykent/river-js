support = require('./../support')

class Count

  constructor: (@args) ->
    @count = 0
    throw new Error("COUNT() should only be called with one argument") unless @args.length is 1
    @field = @args[0]
    
  insert: (record) ->
    oldCount = @count
    val = support.valueForField(@field, record)
    @count += val
    @count unless @count is oldCount
  
  remove: (record) ->
    oldCount = @count
    val = support.valueForField(@field, record)
    @count -= val
    @count unless @count is oldCount
  
exports.fn = Count