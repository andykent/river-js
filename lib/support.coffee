nodes = require('sql-parser').nodes
functions = require('./functions')


exports.valueForField = (field, record) ->
  switch field.constructor 
    when nodes.NumberValue
      field.value
    when nodes.FunctionValue
      fn = functions.get(field.name)
      args = (exports.valueForField(f, record) for f in field.arguments)
      fn.apply(record, args)
    else
      record[field.value]
  