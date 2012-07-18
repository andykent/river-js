river = require('../lib/river')
assert = require('assert')

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
    delete newValues._
    expectedNewValues = expectedValues[callCount]
    withoutMeta(newValues).should.eql(expectedNewValues)
    seenUpdates++
    callCount++

abc = { a:'a', b:'b', c:'c' }

err = (q, msg) ->
  try
    ctx = river.createContext()
    ctx.addQuery(q)
    should.fail('expected an error')
  catch err
    err.message.should.equal(msg)


describe "Unbounded Queries", ->
  beforeEach -> expectedUpdates = seenUpdates = 0
  afterEach -> seenUpdates.should.eql(expectedUpdates)

  it "Compiles 'select *' queries", ->
    ctx = river.createContext()
    q = ctx.addQuery 'SELECT * FROM data'
    q.on('insert', expectUpdate(abc))
    ctx.push('data', abc)

  it "Compiles 'select a, b' queries", ->
    ctx = river.createContext()
    q = ctx.addQuery 'SELECT a, b FROM data'
    q.on('insert', expectUpdate({a:'a', b:'b'}))
    ctx.push('data', abc)

  it "Compiles 'select a AS 'c'' queries", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT a AS c FROM data"
    q.on('insert', expectUpdate({c:'a'}))
    ctx.push('data', abc)

  it "Compiles 'select * WHERE' queries", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT * FROM data WHERE foo = 1"
    q.on('insert', expectUpdate({foo:1}))
    ctx.push('data', foo:2)
    ctx.push('data', foo:1)

  it "Compiles 'LIKE' queries", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT * FROM data WHERE foo LIKE '%bar%'"
    q.on('insert', expectUpdates({foo:'xbarx'},{foo:'zbarz'}))
    ctx.push('data', foo:'car')
    ctx.push('data', foo:'bar')
    ctx.push('data', foo:'xbarx')
    ctx.push('data', foo:'zbarz')

  it "Compiles 'IS NOT' queries", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT * FROM data WHERE foo IS NOT NULL"
    q.on('insert', expectUpdates({foo:'1'},{foo:2}))
    ctx.push('data', foo:'1')
    ctx.push('data', foo:null)
    ctx.push('data', foo:2)
    ctx.push('data', foo:null)

  it "Compiles 'is not' queries in lowercase", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT * FROM data WHERE foo is not null"
    q.on('insert', expectUpdates({foo:'1'},{foo:2}))
    ctx.push('data', foo:'1')
    ctx.push('data', foo:null)
    ctx.push('data', foo:2)
    ctx.push('data', foo:null)

  it "Compiles 'select * WHERE AND' queries", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT * FROM data WHERE foo = 1 AND bar = 2"
    q.on('insert', expectUpdate({foo:1, bar:2}))
    ctx.push('data', foo:1, bar:1)
    ctx.push('data', foo:1, bar:2)

  it "Compiles 'select * WHERE AND nested' queries", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT * FROM data WHERE foo = 1 AND (bar = 2 OR foo = 1)"
    q.on('insert', expectUpdate({foo:1, bar:1}))
    ctx.push('data', foo:1, bar:1)

  it "Compiles 'select with limit' queries", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT * FROM data LIMIT 1"
    q.on('insert', expectUpdate({foo:1, bar:1}))
    ctx.push('data', foo:1, bar:1)
    ctx.push('data', foo:2, bar:2)

  it "Compiles 'select with count(field)' queries", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT COUNT(bar) FROM data"
    q.on('insert', expectUpdates({'COUNT(`bar`)':1},{'COUNT(`bar`)':2}))
    ctx.push('data', foo:'a', bar:1)
    ctx.push('data', foo:'b', bar:null)
    ctx.push('data', foo:'b', bar:'a')

  it "Compiles 'select with count(1)' queries", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT COUNT(1) FROM data"
    q.on('insert', expectUpdates({'COUNT(1)':1},{'COUNT(1)':2},{'COUNT(1)':3}))
    ctx.push('data', foo:'a', bar:1)
    ctx.push('data', foo:'b', bar:null)
    ctx.push('data', foo:'b', bar:'a')

  it "Compiles 'select with sum(1)' queries", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT SUM(1) FROM data"
    q.on('insert', expectUpdates({'SUM(1)':1},{'SUM(1)':2}))
    ctx.push('data', foo:'a', bar:1)
    ctx.push('data', foo:'b', bar:1)


  it "Compiles 'select with sum(field)' queries", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT SUM(foo) AS foo_count FROM data"
    q.on('insert', expectUpdates({foo_count:2},{foo_count:4}))
    ctx.push('data', foo:2, bar:1)
    ctx.push('data', foo:2, bar:1)

  it "Compiles 'select with min(field)' queries", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT MIN(foo) AS foo_min FROM data"
    # TODO: The expectation should actually be this, as it should remove the old value too.
    # q.on('remove', expectUpdates([{foo_min:3}]))
    q.on('insert', expectUpdates({foo_min:3},{foo_min:2}))
    ctx.push('data', foo:3)
    ctx.push('data', foo:4)
    ctx.push('data', foo:2)

  it "Compiles 'select with avg(field)' queries", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT AVG(foo) AS foo_avg FROM data"
    q.on('insert', expectUpdates({foo_avg:3},{foo_avg:2}))
    ctx.push('data', foo:3)
    ctx.push('data', foo:1)

  it "Compiles 'select DISTINCT' queries", ->
    ctx = river.createContext()
    q = ctx.addQuery "SELECT DISTINCT foo FROM data"
    q.on('insert', expectUpdates({foo:1},{foo:2}))
    ctx.push('data', foo:1, bar:1)
    ctx.push('data', foo:1, bar:2)
    ctx.push('data', foo:2, bar:1)

  describe "Functions", ->
    it "Compiles Functions", ->
      ctx = river.createContext()
      q = ctx.addQuery "SELECT LENGTH(foo) as foo_l FROM data"
      q.on('insert', expectUpdate({foo_l:3}))
      ctx.push('data', foo:'bar')

    it "Compiles Functions in lower case", ->
      ctx = river.createContext()
      q = ctx.addQuery "SELECT length(foo) as foo_l FROM data"
      q.on('insert', expectUpdate({foo_l:3}))
      ctx.push('data', foo:'bar')

    it "Compiles nested Functions", ->
      ctx = river.createContext()
      q = ctx.addQuery "SELECT MAX(NUMBER(foo)) as bar FROM data"
      q.on('insert', expectUpdate({bar:3}))
      ctx.push('data', foo:'3')

    it "Compiles Functions in conditions", ->
      ctx = river.createContext()
      q = ctx.addQuery "SELECT foo FROM data WHERE LENGTH(foo) > 2"
      q.on('insert', expectUpdate({foo:'yes'}))
      ctx.push('data', foo:'no')
      ctx.push('data', foo:'yes')

    it "Compiles IF conditions", ->
      ctx = river.createContext()
      q = ctx.addQuery "SELECT IF(LENGTH(foo) = 3, 1, 2) AS f FROM data"
      q.on('insert', expectUpdate({f:1}))
      ctx.push('data', foo:'yes')

    it "Compiles Expressions in place of fields", ->
      ctx = river.createContext()
      q = ctx.addQuery "SELECT foo+1, foo FROM data"
      q.on('insert', expectUpdate({foo:1, '(`foo` + 1)':2}))
      ctx.push('data', foo:1)

    it "Compiles nested expressions in functions", ->
      ctx = river.createContext()
      q = ctx.addQuery "SELECT foo, FLOOR(LENGTH(foo)+1) AS x FROM data"
      q.on('insert', expectUpdate({foo:'1', 'x':2}))
      ctx.push('data', foo:'1')

  describe "Aggregations", ->
    it "Compiles nested expressions in aggregates", ->
      ctx = river.createContext()
      q = ctx.addQuery "SELECT foo, MIN(LENGTH(foo)+1) AS x FROM data"
      q.on('insert', expectUpdate({foo:'1', 'x':2}))
      ctx.push('data', foo:'1')

    it "Compiles nested object properties using dot syntax", ->
      ctx = river.createContext()
      q = ctx.addQuery "SELECT LENGTH(x.y.z) AS foo FROM data"
      q.on('insert', expectUpdate({foo:3}))
      ctx.push('data', {x:{y:{z:'bar'}}})

    it "Compiles 'select with group' queries", ->
      ctx = river.createContext()
      q = ctx.addQuery "SELECT foo, SUM(1) FROM data GROUP BY foo"
      q.on('insert', expectUpdates({foo:'a', 'SUM(1)':1},{foo:'b', 'SUM(1)':1},{foo:'a', 'SUM(1)':2}))
      q.on('remove', expectUpdates({foo:'a', 'SUM(1)':1}))
      ctx.push('data', foo:'a', bar:1)
      ctx.push('data', foo:'b', bar:1)
      ctx.push('data', foo:'a', bar:1)

    it "Compiles 'select with group and having' queries", ->
      ctx = river.createContext()
      q = ctx.addQuery "SELECT foo, SUM(1) AS s FROM data GROUP BY foo HAVING s > 1"
      q.on('insert', expectUpdates({foo:'a', s:2}))
      ctx.push('data', foo:'a', bar:1)
      ctx.push('data', foo:'b', bar:1)
      ctx.push('data', foo:'a', bar:1)

  describe "sub-selects", ->
    it "Compiles unnamed sub-selects", ->
      ctx = river.createContext()
      q = ctx.addQuery "SELECT * FROM (SELECT * FROM data)"
      q.on('insert', expectUpdate({foo:'bar'}))
      ctx.push('data', foo:'bar')

    it "Compiles named sub-selects with property selections", ->
      ctx = river.createContext()
      q = ctx.addQuery "SELECT d.foo FROM (SELECT * FROM data) d"
      q.on('insert', expectUpdate({'`d.foo`':'bar'}))
      ctx.push('data', foo:'bar')

  describe "JOIN syntax", ->
    it "Compiles equality joins across 2 sources (left side seen first)", ->
      ctx = river.createContext()
      q = ctx.addQuery "SELECT * FROM a JOIN b ON a.id = b.id"
      q.on('insert', expectUpdate({ a:{id:2}, b:{id:2} }))
      ctx.push('a', id:1)
      ctx.push('a', id:2)
      ctx.push('b', id:2)

    it "Compiles equality joins across 2 sources (right side seen first)", ->
      ctx = river.createContext()
      q = ctx.addQuery "SELECT * FROM a JOIN b ON a.id = b.id"
      q.on('insert', expectUpdate({ a:{id:2}, b:{id:2} }))
      ctx.push('b', id:1)
      ctx.push('b', id:2)
      ctx.push('a', id:2)

    it "Compiles equality joins across 3 sources", ->
      ctx = river.createContext()
      q = ctx.addQuery "SELECT * FROM a JOIN b ON a.id = b.id JOIN c ON b.id = c.id"
      q.on('insert', expectUpdate({ a:{id:2}, b:{id:2}, c:{id:2} }))
      ctx.push('a', id:1)
      ctx.push('a', id:2)
      ctx.push('b', id:2)
      ctx.push('c', id:1)
      ctx.push('c', id:2)

  describe "UNION syntax", ->
    it "Compiles UNION ALL queries", ->
      ctx = river.createContext()
      q = ctx.addQuery "SELECT * FROM a UNION ALL SELECT * FROM b"
      q.on('insert', expectUpdates({foo:'a'}, {foo:'b'}))
      ctx.push('a', foo:'a')
      ctx.push('b', foo:'b')

    it "throws an error for non ALL unions", ->
      err "SELECT * FROM a UNION SELECT * FROM b", 'UNIONs are only supported with UNION ALL'

  describe "metadata", ->
    it "adds a timestamp to queries", ->
      ctx = river.createContext()
      q = ctx.addQuery 'SELECT * FROM data'
      q.on 'insert', (data) -> assert.ok(data._.ts.constructor is Date)
      ctx.push('data', abc)

    it "adds a UUID to queries", ->
      ctx = river.createContext()
      q = ctx.addQuery 'SELECT * FROM data'
      q.on 'insert', (data) -> data._.uuid.should.be.a('string')
      ctx.push('data', abc)

    it "adds a source to queries", ->
      ctx = river.createContext()
      q = ctx.addQuery 'SELECT * FROM data'
      q.on 'insert', (data) -> data._.src.should.eql('data')
      ctx.push('data', abc)

