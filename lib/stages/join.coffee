{BaseStage} = require('./base')
stages = require('../stages')
{ExpressionCompiler} = require('./../expression_compiler')


# Join
# ---------
# Represents a logical joining of 2 data sources currently
# only supports INNER joins. More types coming soon.
exports.Join = class Join extends BaseStage
  
  LEFT = 'leftTable'
  RIGHT = 'rightTable'
  
  constructor: (@context, join, @left, @shouldAliasLeftSide, @leftSideIsWindowed) ->
    @leftTable = []
    @rightTable = []
    @validJoins = []
    @right = new stages.Source(@context, join.right)
    @right.on 'insert', (r) => @insertRight(r)
    @right.on 'remove', (r) => @removeRight(r)
    @right.on 'insertRemove', (i,r) => @insertRemoveRight(i,r)
    @compiledConditions = new ExpressionCompiler(join.conditions)
  
  insert: (data) ->
    @leftTable.push(data)
    @checkMatches(RIGHT, data)
    
  remove: (data) ->
    @invalidate(LEFT, data)
  
  insertRemove: (i,r) ->
    @insert(i)
    @remove(r)
  
  insertRight: (data) ->
    @rightTable.push(data)
    @checkMatches(LEFT, data)
    
  removeRight: (data) ->
    @invalidate(RIGHT, data)
  
  insertRemoveRight: (i,r) ->
    @insertRight(i)
    @removeRight(r)
  
  checkMatches: (side, data) ->
    for row in this[side]
      combined = @combine(row, data)
      if @compiledConditions.exec(combined)
        @emit('insert', combined) 
        @validJoins.push(combined) if @joinsNeedTracking()
    null
  
  combine: (l,r) ->
    if @shouldAliasLeftSide
      ret = {}
      ret[@left.alias] = l
      ret[@right.alias] = r
      ret
    else
      l[@right.alias] = r 
      l
  
  invalidate: (side, data) ->
    table = this[side]
    table.splice(table.indexOf(data), 1)
    a = if side is LEFT then @left.alias else @right.alias
    for row, i in @validJoins when row[a] is data
      @validJoins.splice(i,1)
      @emit('remove', row)
    null
    
  joinsNeedTracking: ->
    @leftSideIsWindowed or @right.isWindowed()