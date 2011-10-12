nodes = require('sql-parser').nodes
functions = require('./functions')



exports.ExpressionCompiler = class ExpressionCompiler
  constructor: (@conditions) ->
    @compile(@conditions)
  
  exec: (context) ->
    @compiledConditions(context, functions)
  
  compile: (condition) ->
    compiledString = @compileNode(condition)
    compiledFunction = new Function('c', 'f', "return #{compiledString}")
    @compiledConditions = compiledFunction
  
  compileNode: (node) ->
    if node.constructor is nodes.Op
      @compileOperator(node)
    else
      @literalConversion(node)
  
  compileOperator: (condition) ->
    left = @compileNode(condition.left)
    right = @compileNode(condition.right)
    switch condition.operation.toUpperCase()
      when 'LIKE'
        "#{@likeRegex(condition.right)}.test(#{left})"
      else
        op = @conditionConversion(condition.operation)
        ['(', left, op, right, ')'].join(' ')
    
  
  literalConversion: (node) ->
    switch node.constructor 
      when nodes.LiteralValue
        selector = ("['#{v}']" for v in node.values).join('')
        "c#{selector}"
      when nodes.FunctionValue
        fn = "f.get('#{node.name}')"
        args = (@compileNode(arg) for arg in node.arguments)
        "#{fn}(#{args.join(', ')})"
      else
        val = node.value
        if typeof val is 'string'
          "'#{val}'"
        else if val is null
          'null'
        else
          val
      
  likeRegex: (node) ->
    # escape regex chars
    r = node.value.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&")
    # replace % sign with wildcard regex
    r = r.replace(/%/g, '.+')
    "/^#{r}$/"
  
  conditionConversion: (op) ->
    switch op
      when 'AND'    then '&&'
      when 'OR'     then '||'
      when '='      then '==='
      when 'IS NOT' then '!=='
      when 'IS'     then '==='
      else
        op
  
