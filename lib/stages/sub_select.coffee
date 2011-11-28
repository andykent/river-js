{BaseStage} = require('./base')
stages = require('../stages')

# SubSelect
# ---------
# A small wrapper over Select nodes to handle aliasing
# and other things that are needed for subqueries.
exports.SubSelect = class SubSelect extends BaseStage
  
  constructor: (subSelect, streamManager) ->
    @query = subSelect.select
    @alias = subSelect.name
    @select = new stages.Select(@query, streamManager)
    @select.on 'insert', (newValues) => @emit('insert', @alised(newValues))
    @select.on 'remove', (oldValues) => @emit('remove', @alised(oldValues))
    
  insert: (data) ->
    @select.insert(data)

  remove: (data) ->
    @select.remove(data)

  insertRemove: (i,r) ->
    @select.insertRemove(i,r)
  
  alised: (data) ->
    return data unless @alias
    obj = {}
    obj[@alias.value] = data
    obj