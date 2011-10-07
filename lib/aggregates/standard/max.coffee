support = require('./../../support')

class Max

  constructor: (@args) ->
    @max = null
    throw new Error("MIN() should only be called with one argument") unless @args.length is 1
    @field = @args[0]
    
  insert: (record) ->
    oldMax = @max
    val = support.valueForField(@field, record)
    val = Number(val) unless typeof val is 'number'
    @max = val if @max is null or val > @max
    @max unless @max is oldMax
  
exports.fn = Max