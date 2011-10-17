class Max

  constructor: (@args) ->
    @seen = []
    @max = null
    throw new Error("MIN() should only be called with one argument") unless @args.length is 1
    @field = @args[0]
    
  insert: (record) ->
    val = @field.exec(record)
    val = Number(val) unless typeof val is 'number'
    @seen.push(val)
    @max = val if @max is null or val > @max
    @max
    
  remove: (record) ->
    val = @field.exec(record)
    val = Number(val) unless typeof val is 'number'
    idx = @seen.indexOf(val)
    @seen.splice(idx, 1) unless idx is -1
    if val == @max
      @max = Math.max.apply( Math, @seen )
    @max
    
exports.fn = Max