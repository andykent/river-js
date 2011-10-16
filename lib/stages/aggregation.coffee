{BaseStage} = require('./base')
aggregates = require('./../aggregates')
functions = require('./../functions')
nodes = require('sql-parser').nodes

exports.Aggregation = class Aggregation extends BaseStage

  constructor: (@fields, @groupFields=null) ->
    @grouped = true if @groupFields?
    @storedRecords = {}
  
  insert: (record) ->
    @run('insert', record)
  
  remove: (record) ->
    @run('remove', record)
  
  insertRemove: (i, r) ->
    @run('insertRemove', i, r)
    
  run: (mode, record, record2) ->
    key = @makeKey(record)
    oldRecord = @storedRecords[key]
    if mode is 'insertRemove'
      key2 = @makeKey(record2)
      oldRecord2 = @storedRecords[key2]
      @storedRecords[key2] = @aggregate('remove', key2, record2)
      @storedRecords[key]  = @aggregate('insert', key, record)
      if key isnt key2
        if @recordsDiffer(@storedRecords[key2], oldRecord2)
          @emit('remove', oldRecord2) if oldRecord2?
          @emit('insert', @storedRecords[key2])
    else
      @storedRecords[key] = @aggregate(mode, key, record)
    if @recordsDiffer(@storedRecords[key], oldRecord)
      @emit('remove', oldRecord) if oldRecord?
      @emit('insert', @storedRecords[key])
  
  aggregate: (mode, key, record) ->
    result = {}
    for field in @fields
      result[field.name] = field.perform(mode, record, key)
    result
  
  recordsDiffer: (a, b) ->
    JSON.stringify(a) isnt JSON.stringify(b)
    
  makeKey: (record) ->
    return '__DEFAULT__' unless @grouped
    ret = {}
    for field in @groupFields
      ret[field.value] = record[field.value]
    JSON.stringify(ret)
