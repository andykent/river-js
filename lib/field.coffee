nodes = require('sql-parser').nodes
aggregates = require('./aggregates')
{ExpressionCompiler} = require('./expression_compiler')

# Field
# -----
# Instances of this object represent a field that we are trying
# to calculate into the output stream.
#
# it wraps all the known info about a field like it's aliased name,
# it's expression and whether it uses aggregation or functions.
exports.Field = class Field
  
  # Create a new `Field` from a SQL Node
  # an optional second argument allows you to
  # inform the field that it needs windowing support
  # this info is used when making function choices.
  constructor: (@context, @node, @isWindowed=false) ->
    @star = @node.star
    unless @star
      @name = @_name()
      @buckets = {}
  
  # `Field.fieldListFromNodes()` iterates through a Node Array and
  # wraps each Node into a Field object.
  @fieldListFromNodes: (context, nodes, isWindowed=false) ->
    (new Field(context, f, isWindowed) for f in nodes)
  
  # insert a record into this Field
  # the bucket is used to seperate GROUPed fields
  # is the query isn't GROUPed the bucket will be __DEFAULT__
  insert: (record, bucket) ->
    @perform('insert', record, bucket)
    
  # remove a record from this Field 
  # also takes an additional argument to drop the bucket
  # this is used when there is no more records in the bucket
  # without it buckets would never get cleaned up and leak RAM
  remove: (record, bucket, dropBucket=false) ->
    @perform('remove', record, bucket)
  
  # An abstraction of insert/remove logic
  perform: (mode, record, bucket, dropBucket=false) ->
    ret = @bucket(bucket)[mode](record)
    @dropBucket(bucket) if dropBucket is true
    ret
  
  # returns true if this is a non-aggregating function
  isUDF: -> @node.field.udf
  
  # returns true if this field is a function
  isFunction: -> 
    @node.field? and @node.field.constructor is nodes.FunctionValue

  # returns true if the field is an expression rather than a plain literal
  isExpression: ->
    @node.field? and @node.field.constructor is nodes.Op
  
  # returns the bucket value for a given key
  # if the bucket doesn't exist it is compiled.
  bucket: (key) ->
    @buckets[key] ?= @_compile()
    @buckets[key]
  
  # removes a named bucket to reclaim it's memory
  dropBucket: (key) ->
    delete @buckets[key]
  
  # returns true if the field is aggregating
  isAggregate: ->
    @isFunction() and not @node.field.udf
  
  # calcualtes the name of the field
  _name: ->
    return @node.name.value.toString() if @node.name
    if @isFunction() or @isExpression()
      @node.toString()
    else
      @node.field.value
  
  # compiles an object to be assigned to a bucket.
  # The returned object has the properties `insert` and `remove`
  # which are functions that are (mostly) stateful functions.
  _compile: ->
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
    exp = new ExpressionCompiler(@node.field, @context.udfs)
    {
      insert: (record) -> exp.exec(record)
      remove: (record) -> exp.exec(record)
    }
  
  _compileFunctionArgs: () ->
    (new ExpressionCompiler(arg, @context.udfs) for arg in @node.field.arguments)
    