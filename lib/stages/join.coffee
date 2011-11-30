{BaseStage} = require('./base')
stages = require('../stages')
{ExpressionCompiler} = require('./../expression_compiler')


# Join
# ---------
# Represents a logical joining of 2 data sources
# Currently only supports insert streams and
# LEFT sided INNER joins. More types coming soon.
exports.Join = class Join extends BaseStage
  
  constructor: (join, streamManager, @leftAlias=null) ->
    @leftTable = []
    @right = new stages.Source(join.right, streamManager)
    @right.on 'insert', (r) => @insertRight(r)
    @right.on 'remove', (r) => @removeRight(r)
    @right.on 'insertRemove', (i,r) => @insertRemoveRight(i,r)
    @rightAlias = @right.alias
    # NOTE TYPO IN sql-parser: condtions Vs conditions!
    @compiledConditions = new ExpressionCompiler(join.condtions)
  insert: (data) ->
    @leftTable.push(data)
  
  insertRight: (data) ->
    for match in @findMatches(data)
      @emit('insert', match)
  
  findMatches: (data) ->
    matches = []
    for row in @leftTable
      combined = @combine(row, data)
      matches.push(combined) if @compiledConditions.exec(combined)
    matches
  
  combine: (l,r) ->
    if @leftAlias
      ret = {}
      ret[@leftAlias] = l
      ret[@rightAlias] = r
      ret
    else
      l[@rightAlias] = r 
      l