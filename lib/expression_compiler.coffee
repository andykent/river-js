nodes = require('sql-parser').nodes
functions = require('./functions')

# ExpressionCompiler
# ------------------
# Takes a set of nodes that form an expression and compiles
# them into a JS Function which can later be called against 
# a record to evaluate a result.
exports.ExpressionCompiler = class ExpressionCompiler
  
  # Takes the nodes the node tree that makes up this epxression
  # compiles immediately
  constructor: (@conditions) ->
    @usedProperties = []
    @compile(@conditions)
    
  # Evaluate the compiled expression in a given context
  # In most cases the context will be a record.
  exec: (context) ->
    @compiledConditions(context, functions)
  
  # The heavy lifting of compiling the expression happens here.
  # We recurse down the node tree compiling each node into a String
  # then using the awesome dynamic nature of JS we create a new JS
  # function from the String.
  compile: (condition) ->
    compiledString = @compileNode(condition)
    compiledFunction = new Function('c', 'f', "return #{compiledString}")
    @compiledConditions = compiledFunction
  
  # takes a node and decides whether it's an operator or a literal
  # at the end of a branch.
  compileNode: (node) ->
    if node.constructor is nodes.Op
      @compileOperator(node)
    else
      @literalConversion(node)
  
  # Recurse down through the node tree
  # compiling operators into strings as we go.
  # each operator gets wrapped in parens so that
  # associations are explicit.
  compileOperator: (condition) ->
    left = @compileNode(condition.left)
    right = @compileNode(condition.right)
    switch condition.operation.toUpperCase()
      when 'LIKE'
        "#{@likeRegex(condition.right)}.test(#{left})"
      else
        op = @conditionConversion(condition.operation)
        ['(', left, op, right, ')'].join(' ')
    
  # Take a non Op node and create a JS string that can
  # get the required value from the current context (c)
  literalConversion: (node) ->
    switch node.constructor 
      when nodes.LiteralValue
        @usedProperties.push(node.values)
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
    
  # This is propably not the right place for this but until
  # we add RLIKE support its an edge case.
  likeRegex: (node) ->
    # escape regex chars
    r = node.value.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&")
    # replace % sign with wildcard regex
    r = r.replace(/%/g, '.+')
    "/^#{r}$/"
  
  # Convert SQL operators into their JS equiv
  conditionConversion: (op) ->
    switch op.toUpperCase()
      when 'AND'    then '&&'
      when 'OR'     then '||'
      when '='      then '==='
      when 'IS NOT' then '!=='
      when 'IS'     then '==='
      else
        op
  
