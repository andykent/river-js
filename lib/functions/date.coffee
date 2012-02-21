exports.fn = (timeStr, fmt=null) ->
  if typeof timeStr is 'string'
    new Date(Date.parse(timeStr, fmt))
  else if typeof timeStr is 'number'
    new Date(timeStr)
  else
    timeStr