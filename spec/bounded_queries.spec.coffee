river = require('../lib/river')

expectedUpdates = 0
seenUpdates = 0

ensureUpdates = ->
  expect(seenUpdates).toEqual(expectedUpdates)
  expectedUpdates = 0
  seenUpdates = 0

expectUpdate = (expectedValues) ->
  (newValues) ->
    expect(newValues).toEqual(expectedValues)

expectUpdates = (expectedValues...) ->
  expectedUpdates += expectedValues.length
  callCount = 0
  (newValues) ->
    expectedNewValues = expectedValues[callCount]
    expect(newValues).toEqual(expectedNewValues)
    seenUpdates++
    callCount++

describe "Bounded Queries", ->
  it "Compiles length based queries", ->
    ctx = river.createContext()
    query = ctx.addQuery 'SELECT * FROM data.win:length(2)'
    query.on('insert', expectUpdates({foo:1},{foo:2},{foo:3}))
    query.on('remove', expectUpdates({foo:1}))
    ctx.push('data', foo:1)
    ctx.push('data', foo:2)
    ctx.push('data', foo:3)
    ensureUpdates()

  it "Compiles where conditions", ->
    ctx = river.createContext()
    query = ctx.addQuery 'SELECT * FROM data.win:length(2) WHERE foo > 1'
    query.on('insert', expectUpdates({foo:2},{foo:3},{foo:4}))
    query.on('remove', expectUpdates({foo:2},{foo:3}))
    ctx.push('data', foo:1)
    ctx.push('data', foo:2)
    ctx.push('data', foo:1)
    ctx.push('data', foo:3)
    ctx.push('data', foo:1)
    ctx.push('data', foo:4)
    ensureUpdates()

  it "Compiles projections", ->
    ctx = river.createContext()
    query = ctx.addQuery 'SELECT foo AS bar FROM data.win:length(2) WHERE foo > 1'
    query.on('insert', expectUpdates({bar:2},{bar:3},{bar:4}))
    query.on('remove', expectUpdates({bar:2},{bar:3}))
    ctx.push('data', foo:1)
    ctx.push('data', foo:2)
    ctx.push('data', foo:1)
    ctx.push('data', foo:3)
    ctx.push('data', foo:1)
    ctx.push('data', foo:4)
    ensureUpdates()

  it "Compiles aggregations", ->
    ctx = river.createContext()
    query = ctx.addQuery 'SELECT COUNT(foo) AS bar FROM data.win:length(2)'
    query.on('insert', expectUpdates({bar:1},{bar:3},{bar:5}))
    query.on('remove', expectUpdates({bar:1},{bar:3}))
    ctx.push('data', foo:1)
    ctx.push('data', foo:2)
    ctx.push('data', foo:3)
    ensureUpdates()

  # it "doesn't emit aggregations when no change", ->
  #   ctx = river.createContext()
  #   query = ctx.addQuery 'SELECT COUNT(foo) AS bar FROM data.win:length(2)'
  #   query.on('insert', expectUpdates({bar:1},{bar:3}))
  #   query.on('remove', expectUpdates({bar:1}))
  #   ctx.push('data', foo:1)
  #   ctx.push('data', foo:0)
  #   ctx.push('data', foo:3)
  #   ensureUpdates()

  it "Compiles multiple aggregations ", ->
    ctx = river.createContext()
    query = ctx.addQuery 'SELECT COUNT(foo) AS bar, COUNT(x) AS y FROM data.win:length(2)'
    query.on('insert', expectUpdates({bar:1,y:1},{bar:3,y:3},{bar:5,y:5}))
    query.on('remove', expectUpdates({bar:1,y:1},{bar:3,y:3}))
    ctx.push('data', foo:1, x:1)
    ctx.push('data', foo:2, x:2)
    ctx.push('data', foo:3, x:3)
    ensureUpdates()
    