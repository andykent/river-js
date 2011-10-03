nodes = require('sql-parser').nodes

class Min

  constructor: (@args) ->
    @min = null
    throw new Error("MIN() should only be called with one argument") unless @args.length is 1
    @field = @args[0]
    
  push: (record) ->
    oldMin = @min
    val = @valueFor(record)
    @min = val if @min is null or val < @min
    @min
  
  valueFor: (record) ->
    if @field.constructor is nodes.NumberValue
      @field.value
    else
      record[@field.value]
  
exports.fn = Min