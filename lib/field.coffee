nodes = require('sql-parser').nodes
functions = require('./functions')
aggregates = require('./aggregates')
{ExpressionCompiler} = require('./expression_compiler')

exports.Field = class Field
  constructor: (@node) ->
    @star = @node.star
    unless @star
      @name = @_name()
      @isAggregate = false
      @_compile()
  
  insert: (record) ->
    @perform('insert', record)
  
  remove: (record) ->
    @perform('remove', record)
      
  perform: (mode, record) ->
    if @isFunction()
      if @isUDF()
        @_function.apply(record, @buildFnArgs(@node.field.arguments, record))
      else
        @_function[mode](record) # insert / remove
    else if @isExpression()
      @_expression.exec(record)
    else
      record[@node.field.value]
  
  isUDF: -> @node.field.udf
  
  isFunction: -> 
    @node.field? and @node.field.constructor is nodes.FunctionValue

  isExpression: ->
    @node.field? and @node.field.constructor is nodes.Op
  
  _name: ->
    return @node.name.value.toString() if @node.name
    if @isFunction() or @isExpression()
      @node.toString()
    else
      @node.field.value
  
  _compile: ->
    if @isFunction()
      if @node.field.udf
        @_function = functions.get(@node.field.name)
      else
        @isAggregate = true
        klass = aggregates.get(@node.field.name)
        instance = new klass(@node.field.arguments)
        @_function = instance
    if @isExpression()
      @_expression = new ExpressionCompiler(@node.field)

  buildFnArgs: (args, record) ->
    fnArgs = []
    for arg in args
      switch arg.constructor 
        when nodes.NumberValue  then arg.value
        when nodes.LiteralValue then record[arg.value]
        else arg.value

  # initExpressions: () ->
  #   @expressions = {}
  #   for field in @fields when @fieldIsExpression(field.field)
  #     @expressions[@fieldName(field)] = new ExpressionCompiler(field.field) 
  # 
  # initFunctions: () ->
  #   @functions = {}
  #   for field in @fields when @fieldIsFunction(field.field)
  #     if field.field.udf
  #       @functions[@fieldName(field)] = functions.get(field.field.name)
  #     else
  #       @hasAggregation = true
  #       klass = aggregates.get(field.field.name)
  #       instance = new klass(field.field.arguments)
  #       @functions[@fieldName(field)] = instance