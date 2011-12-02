river = require('../lib/river')

expectedUpdates = 0
seenUpdates = 0

withoutMeta = (obj) ->
  delete obj._ if obj._
  obj[k] = withoutMeta(v) for k, v of obj when typeof v is 'object'
  obj

expectUpdate = (expectedValues) ->
  expectedUpdates += 1
  (newValues) ->
    withoutMeta(newValues).should.eql(expectedValues)
    seenUpdates++

expectUpdates = (expectedValues...) ->
  expectedUpdates += expectedValues.length
  callCount = 0
  (newValues) ->
    expectedNewValues = expectedValues[callCount]
    withoutMeta(newValues).should.eql(expectedNewValues)
    seenUpdates++
    callCount++

describe "Bounded Queries", ->
  beforeEach -> expectedUpdates = seenUpdates = 0
  afterEach -> seenUpdates.should.eql(expectedUpdates)
  
  it "Compiles length based queries", ->
    ctx = river.createContext()
    query = ctx.addQuery 'SELECT * FROM data.win:length(2)'
    query.on('insert', expectUpdates({foo:1},{foo:2},{foo:3}))
    query.on('remove', expectUpdates({foo:1}))
    ctx.push('data', foo:1)
    ctx.push('data', foo:2)
    ctx.push('data', foo:3)

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
  
  describe "Aggregations", ->
    it "Compiles count aggregations", ->
      ctx = river.createContext()
      query = ctx.addQuery 'SELECT SUM(foo) AS bar FROM data.win:length(2)'
      query.on('insert', expectUpdates({bar:1},{bar:3},{bar:5}))
      query.on('remove', expectUpdates({bar:1},{bar:3}))
      ctx.push('data', foo:1)
      ctx.push('data', foo:2)
      ctx.push('data', foo:3)

    it "Compiles max aggregations", ->
      ctx = river.createContext()
      query = ctx.addQuery 'SELECT MAX(foo) AS bar FROM data.win:length(2)'
      query.on('insert', expectUpdates({bar:3},{bar:2}))
      query.on('remove', expectUpdates({bar:3}))
      ctx.push('data', foo:3)
      ctx.push('data', foo:2)
      ctx.push('data', foo:1)

    it "doesn't emit aggregations when no change", ->
      ctx = river.createContext()
      query = ctx.addQuery 'SELECT SUM(foo) AS bar FROM data.win:length(2)'
      query.on('insert', expectUpdates({bar:1},{bar:3}))
      query.on('remove', expectUpdates({bar:1}))
      ctx.push('data', foo:1)
      ctx.push('data', foo:0)
      ctx.push('data', foo:3)

    it "Compiles multiple aggregations ", ->
      ctx = river.createContext()
      query = ctx.addQuery 'SELECT SUM(foo) AS bar, SUM(x) AS y FROM data.win:length(2)'
      query.on('insert', expectUpdates({bar:1,y:1},{bar:3,y:3},{bar:5,y:5}))
      query.on('remove', expectUpdates({bar:1,y:1},{bar:3,y:3}))
      ctx.push('data', foo:1, x:1)
      ctx.push('data', foo:2, x:2)
      ctx.push('data', foo:3, x:3)

    it "Compiles group by statements", ->
      ctx = river.createContext()
      query = ctx.addQuery 'SELECT foo, SUM(1) AS foo_count FROM data.win:length(3) GROUP BY foo'
      query.on('insert', expectUpdates({foo:'x',foo_count:1},{foo:'y',foo_count:1},{foo:'x',foo_count:2},{foo:'x',foo_count:1},{foo:'y',foo_count:2}))
      query.on('remove', expectUpdates({foo:'x',foo_count:1},{foo:'x',foo_count:2},{foo:'y',foo_count:1}))
      ctx.push('data', foo:'x')
      ctx.push('data', foo:'y')
      ctx.push('data', foo:'x')
      ctx.push('data', foo:'y')
  
  describe "JOIN syntax", ->
    it "Compiles joins with bounded base source", ->
      ctx = river.createContext()
      q = ctx.addQuery "SELECT * FROM a.win:length(1) JOIN b ON a.id = b.id"
      q.on('insert', expectUpdate({ a:{id:3}, b:{id:3} }))
      q.on('remove', expectUpdate({ a:{id:3}, b:{id:3} }))
      ctx.push('a', id:2)
      ctx.push('a', id:1)
      ctx.push('b', id:2)
      ctx.push('a', id:3)
      ctx.push('b', id:3)    
      ctx.push('a', id:4)
  