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
    @compiledConditions = new ExpressionCompiler(join.conditions, @context.udfs)
    @setupIndex()

  setupIndex: ->
    @isIndexed = @shouldAliasLeftSide and @compiledConditions.isSimpleEquality()
    if @isIndexed
      @index = {}
      @index[LEFT]  = {}
      @index[RIGHT] = {}

  insert: (data) ->
    @leftTable.push(data)
    @addToIndex(LEFT, data)
    @checkMatches(RIGHT, data)

  remove: (data) ->
    @invalidate(LEFT, data)

  insertRemove: (i,r) ->
    @insert(i)
    @remove(r)

  insertRight: (data) ->
    @rightTable.push(data)
    @addToIndex(RIGHT, data)
    @checkMatches(LEFT, data)

  removeRight: (data) ->
    @invalidate(RIGHT, data)

  insertRemoveRight: (i,r) ->
    @insertRight(i)
    @removeRight(r)

  makeKey: (side, data) ->
    data = if side is LEFT then @combine(data,{}) else @combine({},data)
    @compiledConditions.get('left', data) or
    @compiledConditions.get('right', data)

  addToIndex: (side, data) ->
    @index[side][@makeKey(side,data)] = true if @isIndexed

  checkMatches: (side, data) ->
    if @isIndexed
      @checkIndex(side, data)
    else
      @tableScan(side, data)
    null

  checkIndex: (side, data) ->
    opposite = if side is LEFT then RIGHT else LEFT
    if @index[side][@makeKey(side,data)]
      @tableScan(side, data)

  tableScan: (side, data) ->
    for row in this[side]
      combined = @combine(row, data)
      if @compiledConditions.exec(combined)
        @emit('insert', combined)
        @validJoins.push(combined) if @joinsNeedTracking()

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
    if @isIndexed
      delete @index[side][@makeKey(side,data)]
    table = this[side]
    table.splice(table.indexOf(data), 1)
    a = if side is LEFT then @left.alias else @right.alias
    for row, i in @validJoins when row[a] is data
      @validJoins.splice(i,1)
      @emit('remove', row)
    null

  joinsNeedTracking: ->
    @leftSideIsWindowed or @right.isWindowed()