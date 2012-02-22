class Count

  constructor: (@args) ->
    @count = 0
    throw new Error("COUNT() should only be called with one argument") unless @args.length is 1
    @field = @args[0]

  insert: (record) ->
    val = @field.exec(record)
    if val isnt null
      @count++
    @count

exports.fn = Count