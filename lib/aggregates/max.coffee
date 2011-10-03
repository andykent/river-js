nodes = require('sql-parser').nodes

class Max

  constructor: (@args) ->
    @max = null
    throw new Error("MIN() should only be called with one argument") unless @args.length is 1
    @field = @args[0]
    
  push: (record) ->
    oldMax = @max
    val = @valueFor(record)
    @max = val if @max is null or val > @max
    @max
  
  valueFor: (record) ->
    if @field.constructor is nodes.NumberValue
      @field.value
    else
      record[@field.value]
  
exports.fn = Max