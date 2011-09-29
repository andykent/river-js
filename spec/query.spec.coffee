Query = require('../lib/query').Query

wait = jasmine.asyncSpecWait
done = jasmine.asyncSpecDone

expectUpdate = (expectedNewValues=null, expectedOldValues=null) ->
  (newValues, oldValues) ->
    expect(newValues).toEqual(expectedNewValues)
    expect(oldValues).toEqual(expectedOldValues)

abc = { a:'a', b:'b', c:'c' }

describe "Query", ->
  it "Compiles 'select *' queries", ->
    query = new Query('SELECT * FROM data')
    query.on 'update', expectUpdate([abc], null)
    query.push('data', abc)

  it "Compiles 'select a, b' queries", ->
    query = new Query('SELECT a, b FROM data')
    query.on 'update', expectUpdate([{a:'a', b:'b'}], null)
    query.push('data', abc)

  it "Compiles 'select a AS 'c'' queries", ->
    query = new Query("SELECT a AS c FROM data")
    query.on 'update', expectUpdate([{c:'a'}], null)
    query.push('data', abc)

  it "Compiles 'select * WHERE' queries", ->
    query = new Query("SELECT * FROM data WHERE foo = 1")
    query.on 'update', expectUpdate([{foo:1}], null)
    query.push('data', foo:2)
    query.push('data', foo:1)

  it "Compiles 'select * WHERE AND' queries", ->
    query = new Query("SELECT * FROM data WHERE foo = 1 AND bar = 2")
    query.on 'update', expectUpdate([{foo:1, bar:2}], null)
    query.push('data', foo:1, bar:1)
    query.push('data', foo:1, bar:2)

  it "Compiles 'select * WHERE AND nested' queries", ->
    query = new Query("SELECT * FROM data WHERE foo = 1 AND (bar = 2 OR foo = 1)")
    query.on 'update', expectUpdate([{foo:1, bar:1}], null)
    query.push('data', foo:1, bar:1)
    
  it "Compiles 'select with limit' queries", ->
    query = new Query("SELECT * FROM data LIMIT 1")
    query.on 'update', expectUpdate([{foo:1, bar:1}], null)
    query.push('data', foo:1, bar:1)
    query.push('data', foo:2, bar:2)
    
    