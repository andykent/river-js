availableFunctions = 'ABS CEIL CONCAT FLOOR IF LENGTH LOG LOWER ROUND SUBSTR UPPER'.split(' ')
functions = {}
for f in availableFunctions
  functions[f] = require("./functions/#{f.toLowerCase()}").fn

exports.get = (functionName) ->
  f = functions[functionName]
  throw(new Error("UNKNOWN FUNCTION: #{functionName}")) unless f
  f
