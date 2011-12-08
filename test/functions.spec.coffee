require('date-utils')
river = require('../lib/river')
FunctionCollection = require('../lib/functions')
f = new FunctionCollection()

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
  
describe "SQL Functions", ->
  describe "LOWER()", ->
    it "lowercases the input", ->
      f.get('LOWER')('ABC').should.eql('abc')
    it "casts value to a string", ->
      f.get('LOWER')(123).should.eql('123')
  
  describe "UPPER()", ->
    it "uppercases the input", ->
      f.get('UPPER')('abc').should.eql('ABC')
    it "casts value to a string", ->
      f.get('UPPER')(123).should.eql('123')

  describe "CONCAT()", ->
    it "joins args", ->
      f.get('CONCAT')('a', 'b').should.eql('ab')
    it "joins multiple args", ->
      f.get('CONCAT')('a', 'b', 'c').should.eql('abc')
    it "joins arrays args", ->
      f.get('CONCAT')(['a', 'b', 'c']).should.eql('abc')
  
  describe "SUBSTR()", ->
    it "extract part of a string", ->
      f.get('SUBSTR')('abc', 1, 1).should.eql('b')
  
  describe "ROUND()", ->
    it "rounds a number", ->
      f.get('ROUND')(1.2).should.eql(1)
    it "rounds a string", ->
      f.get('ROUND')('1.2').should.eql(1)

  describe "YEAR()", ->
    it "returns the year for a given date", ->
      date = new Date(Date.parse('2011-12-08'))
      f.get('YEAR')(date).should.eql('2011')
    it "returns the year for a given string", ->
      f.get('YEAR')('2011-12-08').should.eql('2011')
    it "returns the year for a given microseconds since epoch", ->
      f.get('YEAR')(1323302400000).should.eql('2011')


describe "User Defined Functions", ->
  it "allows adding a user defined function to a context", ->
    ctx = river.createContext()
    ctx.addFunction('ECHO', (x) -> x)
    q = ctx.addQuery "SELECT ECHO(true) AS foo FROM data"
    q.on('insert', expectUpdate({foo:true}))
    ctx.push('data', a:1)

