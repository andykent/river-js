river = require('../lib/river')

describe "Context", ->  
  it "allows adding queries and gives each sha1 IDs", ->
    ctx = river.createContext()
    q1 = ctx.addQuery("SELECT * FROM data1")
    q2 = ctx.addQuery("SELECT * FROM data2")
    q1.id.should.be.a('string').with.length(40)
    q2.id.should.not.eql(q1.id)

  it "queries with the same semantics shouldn't get duplicated", ->
    ctx = river.createContext()
    q1 = ctx.addQuery("SELECT * FROM data1")
    q2 = ctx.addQuery("SELECT * FROM data1")
    q3 = ctx.addQuery("select  *  from   data1")
    q1.should.equal(q2)
    q1.should.equal(q3)
  
  it "allows removing queries", ->
    ctx = river.createContext()
    q = ctx.addQuery("SELECT * FROM data1")
    ctx.removeQuery(q.id).should.eql(true)

  it "allows pushing data into a context", ->
    ctx = river.createContext()
    ret = ctx.push('data', foo: 'bar')
    ret.should.eql(true)

  it "Selects data from the correct stream", ->
    ctx = river.createContext()
    callCount = 0
    ctx.addQuery("SELECT * FROM yes", -> callCount++)
    ret = ctx.push('yes', foo: 'bar')
    ret = ctx.push('no', foo: 'bar')
    ret = ctx.push('yes', foo: 'bar')
    callCount.should.eql(2)

  it "allows stopping queries", ->
    ctx = river.createContext()
    callCount = 0
    q = ctx.addQuery("SELECT * FROM data", -> callCount++)
    ctx.removeQuery(q)
    ctx.push('data', {foo:'bar'})
    callCount.should.eql(0)

