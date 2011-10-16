nodes = require('sql-parser').nodes
functions = require('./functions')
aggregates = require('./aggregates')
{ExpressionCompiler} = require('./expression_compiler')

exports.Field = class Field
  constructor: (@node, @isWindowed=false) ->
    @star = @node.star
    unless @star
      @name = @_name()
      @buckets = {}
  
  @fieldListFromNodes: (nodes, isWindowed=false) ->
    (new Field(f, isWindowed) for f in nodes)

  insert: (record, bucket) ->
    @perform('insert', record, bucket)
  
  remove: (record, bucket, dropBucket=false) ->
    @perform('remove', record, bucket)
      
  perform: (mode, record, bucket, dropBucket=false) ->
    ret = @bucket(bucket)[mode](record)
    @dropBucket(bucket) if dropBucket is true
    ret
  
  isUDF: -> @node.field.udf
  
  isFunction: -> 
    @node.field? and @node.field.constructor is nodes.FunctionValue

  isExpression: ->
    @node.field? and @node.field.constructor is nodes.Op
  
  bucket: (key) ->
    @buckets[key] ?= @_compile(key)
    @buckets[key]
    
  dropBucket: (key) ->
    delete @buckets[key]
  
  isAggregate: ->
    @isFunction() and not @node.field.udf
  
  _name: ->
    return @node.name.value.toString() if @node.name
    if @isFunction() or @isExpression()
      @node.toString()
    else
      @node.field.value
  
  _compile: (bucket) ->
    if @isAggregate()
      @_compileAggregate()
    else 
      @_compileExpression()
  
  _compileAggregate: ->
    if @isWindowed
      klass = aggregates.getWindowed(@node.field.name)
    else
      klass = aggregates.get(@node.field.name)
    args = @_compileFunctionArgs()
    new klass(args)
    
  _compileExpression: ->
    exp = new ExpressionCompiler(@node.field)
    {
      insert: (record) -> exp.exec(record)
      remove: (record) -> exp.exec(record)
    }
  
  _compileFunctionArgs: () ->
    (new ExpressionCompiler(arg) for arg in @node.field.arguments)