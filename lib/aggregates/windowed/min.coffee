class Min

  constructor: (@args) ->
    @seen = []
    @min = null
    throw new Error("MIN() should only be called with one argument") unless @args.length is 1
    @field = @args[0]
    
  insert: (record) ->
    val = @field.exec(record)
    val = Number(val) unless typeof val is 'number'
    @seen.push(val)
    @min = val if @min is null or val < @min
    @min
  
  remove: (record) ->
    val = @field.exec(record)
    val = Number(val) unless typeof val is 'number'
    idx = @seen.indexOf(val)
    @seen.splice(idx, 1) unless idx is -1
    if val == @min
      @min = Math.min.apply( Math, @seen )
    @min
  
exports.fn = Min