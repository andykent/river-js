river = require('../lib/river')

wait = jasmine.asyncSpecWait
done = jasmine.asyncSpecDone

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


abc = { a:'a', b:'b', c:'c' }

describe "Unbounded Queries", ->
  it "Compiles 'select *' queries", ->
    ctx = river.createContext()
    q = ctx.addQuery 'SELECT * FROM data'
    q.on('insert', expectUpdate(abc))
    ctx.push('data', abc)
    ensureUpdates()

  it "Compiles 'select a, b' queries", ->
    ctx = river.createContext()
    q = ctx.addQuery 'SELECT a, b FROM data'
    q.on('insert', expectUpdate({a:'a', b:'b'}))
    ctx.push('data', abc)
    ensureUpdates()
  it "Compiles 'select a AS 'c'' queries", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT a AS c FROM data"
    q.on('insert', expectUpdate({c:'a'}))
    ctx.push('data', abc)
    ensureUpdates()
    
  it "Compiles 'select * WHERE' queries", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT * FROM data WHERE foo = 1"
    q.on('insert', expectUpdate({foo:1}))
    ctx.push('data', foo:2)
    ctx.push('data', foo:1)
    ensureUpdates()
    
  it "Compiles 'LIKE' queries", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT * FROM data WHERE foo LIKE '%bar%'"
    q.on('insert', expectUpdates({foo:'xbarx'},{foo:'zbarz'}))
    ctx.push('data', foo:'car')
    ctx.push('data', foo:'bar')
    ctx.push('data', foo:'xbarx')
    ctx.push('data', foo:'zbarz')
    ensureUpdates()

  it "Compiles 'IS NOT' queries", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT * FROM data WHERE foo IS NOT NULL"
    q.on('insert', expectUpdates({foo:'1'},{foo:2}))
    ctx.push('data', foo:'1')
    ctx.push('data', foo:null)
    ctx.push('data', foo:2)
    ctx.push('data', foo:null)
    ensureUpdates()
    
  it "Compiles 'select * WHERE AND' queries", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT * FROM data WHERE foo = 1 AND bar = 2"
    q.on('insert', expectUpdate({foo:1, bar:2}))
    ctx.push('data', foo:1, bar:1)
    ctx.push('data', foo:1, bar:2)
    ensureUpdates()
    
  it "Compiles 'select * WHERE AND nested' queries", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT * FROM data WHERE foo = 1 AND (bar = 2 OR foo = 1)"
    q.on('insert', expectUpdate({foo:1, bar:1}))
    ctx.push('data', foo:1, bar:1)
    ensureUpdates()
    
  it "Compiles 'select with limit' queries", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT * FROM data LIMIT 1"
    q.on('insert', expectUpdate({foo:1, bar:1}))
    ctx.push('data', foo:1, bar:1)
    ctx.push('data', foo:2, bar:2)
    ensureUpdates()
    
  it "Compiles 'select with count(field)' queries", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT COUNT(bar) FROM data"
    q.on('insert', expectUpdates({'COUNT(`bar`)':1},{'COUNT(`bar`)':2}))
    ctx.push('data', foo:'a', bar:1)
    ctx.push('data', foo:'b', bar:null)
    ctx.push('data', foo:'b', bar:'a')
    ensureUpdates()

  it "Compiles 'select with count(1)' queries", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT COUNT(1) FROM data"
    q.on('insert', expectUpdates({'COUNT(1)':1},{'COUNT(1)':2},{'COUNT(1)':3}))
    ctx.push('data', foo:'a', bar:1)
    ctx.push('data', foo:'b', bar:null)
    ctx.push('data', foo:'b', bar:'a')
    ensureUpdates()

  it "Compiles 'select with sum(1)' queries", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT SUM(1) FROM data"
    q.on('insert', expectUpdates({'SUM(1)':1},{'SUM(1)':2}))
    ctx.push('data', foo:'a', bar:1)
    ctx.push('data', foo:'b', bar:1)
    ensureUpdates()

    
  it "Compiles 'select with sum(field)' queries", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT SUM(foo) AS foo_count FROM data"
    q.on('insert', expectUpdates({foo_count:2},{foo_count:4}))
    ctx.push('data', foo:2, bar:1)
    ctx.push('data', foo:2, bar:1)
    ensureUpdates()
    
  it "Compiles 'select with min(field)' queries", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT MIN(foo) AS foo_min FROM data"
    # TODO: The expectation should actually be this, as it should remove the old value too.
    # q.on('remove', expectUpdates([{foo_min:3}]))
    q.on('insert', expectUpdates({foo_min:3},{foo_min:2}))
    ctx.push('data', foo:3)
    ctx.push('data', foo:4)
    ctx.push('data', foo:2)
    ensureUpdates()
    
  it "Compiles 'select DISTINCT' queries", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT DISTINCT foo FROM data"
    q.on('insert', expectUpdates({foo:1},{foo:2}))
    ctx.push('data', foo:1, bar:1)
    ctx.push('data', foo:1, bar:2)
    ctx.push('data', foo:2, bar:1)
    ensureUpdates()
    
  it "Compiles Functions", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT LENGTH(foo) as foo_l FROM data"
    q.on('insert', expectUpdate({foo_l:3}))
    ctx.push('data', foo:'bar')
    ensureUpdates()
    
  it "Compiles nested Functions", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT MAX(NUMBER(foo)) as bar FROM data"
    q.on('insert', expectUpdate({bar:3}))
    ctx.push('data', foo:'3')
    ensureUpdates()
    
  it "Compiles Functions in conditions", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT foo FROM data WHERE LENGTH(foo) > 2"
    q.on('insert', expectUpdate({foo:'yes'}))
    ctx.push('data', foo:'no')
    ctx.push('data', foo:'yes')
    ensureUpdates()
    
  it "Compiles IF conditions", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT IF(LENGTH(foo) = 3, 1, 2) AS f FROM data"
    q.on('insert', expectUpdate({f:1}))
    ctx.push('data', foo:'yes')
    ensureUpdates()
  
  it "Compiles Expressions in place of fields", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT foo+1, foo FROM data"
    q.on('insert', expectUpdate({foo:1, '(`foo` + 1)':2}))
    ctx.push('data', foo:1)
    ensureUpdates()

  it "Compiles nested expressions in functions", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT foo, FLOOR(LENGTH(foo)+1) AS x FROM data"
    q.on('insert', expectUpdate({foo:'1', 'x':2}))
    ctx.push('data', foo:'1')
    ensureUpdates()
  
  it "Compiles nested expressions in aggregates", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT foo, MIN(LENGTH(foo)+1) AS x FROM data"
    q.on('insert', expectUpdate({foo:'1', 'x':2}))
    ctx.push('data', foo:'1')
    ensureUpdates()
  
  it "Compiles nested object properties using dot syntax", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT LENGTH(x.y.z) AS foo FROM data"
    q.on('insert', expectUpdate({foo:3}))
    ctx.push('data', {x:{y:{z:'bar'}}})
    ensureUpdates()
  
  it "Compiles 'select with group' queries", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT foo, SUM(1) FROM data GROUP BY foo"
    q.on('insert', expectUpdates({foo:'a', 'SUM(1)':1},{foo:'b', 'SUM(1)':1},{foo:'a', 'SUM(1)':2}))
    q.on('remove', expectUpdates({foo:'a', 'SUM(1)':1}))
    ctx.push('data', foo:'a', bar:1)
    ctx.push('data', foo:'b', bar:1)
    ctx.push('data', foo:'a', bar:1)
    
    