nodes = require('sql-parser').nodes

class Count

  constructor: (@args) ->
    @count = 0
    throw new Error("COUNT() should only be called with one argument") unless @args.length is 1
    @field = @args[0]
    
  push: (record) ->
    oldCount = @count
    @count += @valueFor(record)
    @count unless @count is oldCount
  
  valueFor: (record) ->
    if @field.constructor is nodes.NumberValue
      @field.value
    else
      record[@field.value]
  
exports.fn = Count