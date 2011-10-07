availableFunctions = ['COUNT', 'MIN', 'MAX']
functions = {}
windowedFunctions = {}
for f in availableFunctions
  functions[f] = require("./aggregates/standard/#{f.toLowerCase()}").fn
  windowedFunctions[f] = require("./aggregates/windowed/#{f.toLowerCase()}").fn

exports.get = (functionName) ->
  f = functions[functionName]
  throw(new Error("UNKNOWN FUNCTION: #{functionName}")) unless f
  f

exports.getWindowed = (functionName) ->
  f = windowedFunctions[functionName]
  throw(new Error("UNKNOWN FUNCTION: #{functionName}")) unless f
  f
  