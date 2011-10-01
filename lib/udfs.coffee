availableFunctions = ['LENGTH']
functions = {}
for f in availableFunctions
  functions[f] = require("./udfs/#{f}").fn

exports.get = (functionName) ->
  f = functions[functionName]
  throw(new Error("UNKNOWN FUNCTION")) unless f
  f
