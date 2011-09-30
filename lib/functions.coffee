availableFunctions = ['COUNT']
functions = {}
for f in availableFunctions
  functions[f] = require("./functions/#{f}").fn

exports.get = (functionName) ->
  f = functions[functionName]
  throw(new Error("UNKNOWN FUNCTION")) unless f
  f
  