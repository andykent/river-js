parse = require('./date').fn

exports.fn = (date) ->
  parse(date).getDate()