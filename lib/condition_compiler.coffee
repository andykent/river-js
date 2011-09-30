nodes = require('sql-parser').nodes


exports.ConditionCompiler = class ConditionCompiler
  constructor: (@conditions) ->
    @compile(@conditions)
  
  exec: (context) ->
    @compiledConditions(context)
  
  compile: (condition) ->
    compiledString = @compileNode(condition)
    # console.log(compiledString)
    compiledFunction = new Function('c', "return #{compiledString}")
    @compiledConditions = compiledFunction
  
  compileNode: (condition) ->
    left = @convertOrCompile(condition.left)
    right = @convertOrCompile(condition.right)
    if condition.operation is 'LIKE'
      "#{@likeRegex(condition.right)}.test(#{left})"
    else
      op = @conditionConversion(condition.operation)
      ['(', left, op, right, ')'].join(' ')
    
  
  literalConversion: (node) ->
    if node.constructor is nodes.LiteralValue
      "c['#{node.value}']"
    else
      val = node.value
      if typeof val is 'string'
        "'#{val}'"
      else
        val
      
  likeRegex: (node) ->
    r = node.value.replace(/%/g, '.+')
    "/^#{r}$/"
  
  conditionConversion: (op) ->
    switch op
      when 'AND'  then '&&'
      when 'OR'   then '||'
      when '='    then '=='
      else
        op
  
  convertOrCompile: (node) ->
    if node.constructor is nodes.Op
      @compileNode(node)
    else
      @literalConversion(node)
