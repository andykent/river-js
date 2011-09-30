river = require('../lib/river')

wait = jasmine.asyncSpecWait
done = jasmine.asyncSpecDone

expectUpdate = (expectedNewValues=null, expectedOldValues=null) ->
  (newValues, oldValues) ->
    expect(newValues).toEqual(expectedNewValues)
    expect(oldValues).toEqual(expectedOldValues)

expectUpdates = (expectedValues...) ->
  callCount = 0
  (newValues, oldValues) ->
    [expectedNewValues, expectedOldValues] = expectedValues[callCount]
    expect(newValues).toEqual(expectedNewValues)
    expect(oldValues).toEqual(expectedOldValues)
    callCount++
  

abc = { a:'a', b:'b', c:'c' }

describe "Query", ->
  it "Compiles 'select *' queries", ->
    ctx = river.createContext()
    ctx.addQuery 'SELECT * FROM data', expectUpdate([abc], null)
    ctx.push('data', abc)

  it "Compiles 'select a, b' queries", ->
    ctx = river.createContext()
    ctx.addQuery 'SELECT a, b FROM data', expectUpdate([{a:'a', b:'b'}], null)
    ctx.push('data', abc)

  it "Compiles 'select a AS 'c'' queries", ->
    ctx = river.createContext()
    ctx.addQuery "SELECT a AS c FROM data", expectUpdate([{c:'a'}], null)
    ctx.push('data', abc)

  it "Compiles 'select * WHERE' queries", ->
    ctx = river.createContext()
    ctx.addQuery "SELECT * FROM data WHERE foo = 1", expectUpdate([{foo:1}], null)
    ctx.push('data', foo:2)
    ctx.push('data', foo:1)

  it "Compiles 'select * WHERE AND' queries", ->
    ctx = river.createContext()
    ctx.addQuery "SELECT * FROM data WHERE foo = 1 AND bar = 2", expectUpdate([{foo:1, bar:2}], null)
    ctx.push('data', foo:1, bar:1)
    ctx.push('data', foo:1, bar:2)

  it "Compiles 'select * WHERE AND nested' queries", ->
    ctx = river.createContext()
    ctx.addQuery "SELECT * FROM data WHERE foo = 1 AND (bar = 2 OR foo = 1)", expectUpdate([{foo:1, bar:1}], null)
    ctx.push('data', foo:1, bar:1)
    
  it "Compiles 'select with limit' queries", ->
    ctx = river.createContext()
    ctx.addQuery "SELECT * FROM data LIMIT 1", expectUpdate([{foo:1, bar:1}], null)
    ctx.push('data', foo:1, bar:1)
    ctx.push('data', foo:2, bar:2)
    
  it "Compiles 'select with count(1)' queries", ->
    ctx = river.createContext()
    ctx.addQuery "SELECT COUNT(1) FROM data", 
      expectUpdates([[{'COUNT(1)':1}], null], [[{'COUNT(1)':2}], null])
    ctx.push('data', foo:'a', bar:1)
    ctx.push('data', foo:'b', bar:1)
    
  it "Compiles 'select with count(field)' queries", ->
    ctx = river.createContext()
    ctx.addQuery "SELECT COUNT(foo) AS foo_count FROM data", 
      expectUpdates([[{foo_count:2}], null], [[{foo_count:4}], null])
    ctx.push('data', foo:2, bar:1)
    ctx.push('data', foo:2, bar:1)
    
  it "Compiles 'select DISTINCT' queries", ->
    ctx = river.createContext()
    ctx.addQuery "SELECT DISTINCT foo FROM data",
      expectUpdates([[{foo:1}], null], [[{foo:2}], null])
    ctx.push('data', foo:1, bar:1)
    ctx.push('data', foo:1, bar:2)
    ctx.push('data', foo:2, bar:1)
    
  # it "Compiles 'select with group' queries", ->
  #   ctx = river.createContext()
  #   ctx.addQuery "SELECT foo, COUNT(1) FROM data GROUP BY foo", 
  #     expectUpdates([[{foo:'a', 'COUNT(1)':1}], null], [[{foo:'b', 'COUNT(1)':1}], null], [[{foo:'a', 'COUNT(1)':2}], null])
  #   ctx.push('data', foo:'a', bar:1)
  #   ctx.push('data', foo:'b', bar:1)
  #   ctx.push('data', foo:'a', bar:1)
    
    