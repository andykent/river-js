# Require and export all the available aggregate functions
# See individual aggregates for more info.
#
# In many cases standard aggregates are functionally identical
# to the windowed versions but they have some memory optimisations
# as they don't need to store historic data to support 'remove' streams.

availableFunctions = ['AVG', 'COUNT', 'MIN', 'MAX', 'SUM']
functions = {}
windowedFunctions = {}
for f in availableFunctions
  functions[f] = require("./aggregates/standard/#{f.toLowerCase()}").fn
  windowedFunctions[f] = require("./aggregates/windowed/#{f.toLowerCase()}").fn

# fetch the standard version of this aggregate
exports.get = (functionName) ->
  f = functions[functionName.toUpperCase()]
  throw(new Error("UNKNOWN FUNCTION: #{functionName}")) unless f
  f

# fetch the windowed version of this aggregate
exports.getWindowed = (functionName) ->
  f = windowedFunctions[functionName.toUpperCase()]
  throw(new Error("UNKNOWN FUNCTION: #{functionName}")) unless f
  f
