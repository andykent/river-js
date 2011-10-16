support = require('./../../support')

class Avg

  constructor: (@args) ->
    @count = 0
    @sum = 0
    throw new Error("AVG() should only be called with one argument") unless @args.length is 1
    @field = @args[0]
    
  insert: (record) ->
    val = @field.exec(record)
    val = Number(val) unless typeof val is 'number'
    @count++
    @sum += val
    @sum / @count
  
  remove: (record) ->
    val = @field.exec(record)
    val = Number(val) unless typeof val is 'number'
    @count--
    @sum -= val
    @sum / @count
  
exports.fn = Avg