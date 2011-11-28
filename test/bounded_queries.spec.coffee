river = require('../lib/river')

expectedUpdates = 0
seenUpdates = 0

ensureUpdates = ->
  seenUpdates.should.eql(expectedUpdates)
  expectedUpdates = 0
  seenUpdates = 0

expectUpdate = (expectedValues) ->
  (newValues) ->
    newValues.should.eql(expectedValues)

expectUpdates = (expectedValues...) ->
  expectedUpdates += expectedValues.length
  callCount = 0
  (newValues) ->
    expectedNewValues = expectedValues[callCount]
    newValues.should.eql(expectedNewValues)
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

  it "Compiles count aggregations", ->
    ctx = river.createContext()
    query = ctx.addQuery 'SELECT SUM(foo) AS bar FROM data.win:length(2)'
    query.on('insert', expectUpdates({bar:1},{bar:3},{bar:5}))
    query.on('remove', expectUpdates({bar:1},{bar:3}))
    ctx.push('data', foo:1)
    ctx.push('data', foo:2)
    ctx.push('data', foo:3)
    ensureUpdates()

  it "Compiles max aggregations", ->
    ctx = river.createContext()
    query = ctx.addQuery 'SELECT MAX(foo) AS bar FROM data.win:length(2)'
    query.on('insert', expectUpdates({bar:3},{bar:2}))
    query.on('remove', expectUpdates({bar:3}))
    ctx.push('data', foo:3)
    ctx.push('data', foo:2)
    ctx.push('data', foo:1)
    ensureUpdates()

  it "doesn't emit aggregations when no change", ->
    ctx = river.createContext()
    query = ctx.addQuery 'SELECT SUM(foo) AS bar FROM data.win:length(2)'
    query.on('insert', expectUpdates({bar:1},{bar:3}))
    query.on('remove', expectUpdates({bar:1}))
    ctx.push('data', foo:1)
    ctx.push('data', foo:0)
    ctx.push('data', foo:3)
    ensureUpdates()

  it "Compiles multiple aggregations ", ->
    ctx = river.createContext()
    query = ctx.addQuery 'SELECT SUM(foo) AS bar, SUM(x) AS y FROM data.win:length(2)'
    query.on('insert', expectUpdates({bar:1,y:1},{bar:3,y:3},{bar:5,y:5}))
    query.on('remove', expectUpdates({bar:1,y:1},{bar:3,y:3}))
    ctx.push('data', foo:1, x:1)
    ctx.push('data', foo:2, x:2)
    ctx.push('data', foo:3, x:3)
    ensureUpdates()

  it "Compiles group by statements", ->
    ctx = river.createContext()
    query = ctx.addQuery 'SELECT foo, SUM(1) AS foo_count FROM data.win:length(3) GROUP BY foo'
    query.on('insert', expectUpdates({foo:'x',foo_count:1},{foo:'y',foo_count:1},{foo:'x',foo_count:2},{foo:'x',foo_count:1},{foo:'y',foo_count:2}))
    query.on('remove', expectUpdates({foo:'x',foo_count:1},{foo:'x',foo_count:2},{foo:'y',foo_count:1}))
    ctx.push('data', foo:'x')
    ctx.push('data', foo:'y')
    ctx.push('data', foo:'x')
    ctx.push('data', foo:'y')
    ensureUpdates()
    