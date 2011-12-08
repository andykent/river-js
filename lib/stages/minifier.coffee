{BaseStage} = require('./base')
{ExpressionCompiler} = require('./../expression_compiler')

exports.Minifier = class Minifier extends BaseStage

  constructor: (@context, query) ->
    @star = false
    @fields = []
    @discoverFields(query)
  insert: (data) ->
    if @star
      minData = data
    else
      minData = {}
      for selector in @fields
        n = data
        nn = minData
        for i, f of selector
          if i < selector.length - 1 
            n = n[f]
            nn[f] ?= {}
            nn = nn[f]
          else
            nn[f] = n[f]
    @emit('insert', minData)
  
  discoverFields: (query) ->
    for s in query.fields
      if s.star
        @star = true
        return
      c = new ExpressionCompiler(s.field, @context.udfs)
      @fields.push(p) for p in c.usedProperties when @fields.indexOf(p) is -1
    
    if query.where?
      c = new ExpressionCompiler(query.where.conditions, @context.udfs)
      @fields.push(p) for p in c.usedProperties when @fields.indexOf(p) is -1
    
    if query.group?
      c = new ExpressionCompiler(query.group.fields, @context.udfs)
      @fields.push(p) for p in c.usedProperties when @fields.indexOf(p) is -1
      