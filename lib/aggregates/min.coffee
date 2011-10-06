support = require('./../support')

class Min

  constructor: (@args) ->
    @min = null
    throw new Error("MIN() should only be called with one argument") unless @args.length is 1
    @field = @args[0]
    
  insert: (record) ->
    oldMin = @min
    val = support.valueForField(@field, record)
    @min = val if @min is null or val < @min
    @min unless @min is oldMin
  
exports.fn = Min