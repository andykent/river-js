# Require and export all the available functions
# See individual functions for more info.
availableFunctions = 'ABS CEIL CONCAT DATE DAY FLOOR HOUR IF LENGTH LOG LOWER MINUTE MONTH NUMBER YEAR ROUND SECOND STRFTIME STRING SUBSTR UPPER UNESCAPE'.split(' ')
functions = {}
for f in availableFunctions
  functions[f] = require("./functions/#{f.toLowerCase()}").fn

# fetch a function by name
module.exports = class FunctionCollection
  constructor: (@udfs={}) -> null

  get: (functionName) ->
    f = functions[functionName.toUpperCase()] or @udfs[functionName.toUpperCase()]
    throw(new Error("UNKNOWN FUNCTION: #{functionName}")) unless f
    f
