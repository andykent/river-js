parse = require('./date').fn

exports.fn = (date, fmt=null) ->
  if fmt
    parse(date).toFormat(fmt)
  else
    parse(date).toDBString()