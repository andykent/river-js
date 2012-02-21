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
      f.get('YEAR')(date).should.eql(2011)
    it "returns the year for a given string", ->
      f.get('YEAR')('2011-12-08').should.eql(2011)
    it "returns the year for a given microseconds since epoch", ->
      f.get('YEAR')(1323302400000).should.eql(2011)

  describe "MONTH()", ->
    it "returns the value for a given string", ->
      f.get('MONTH')('2011-12-08').should.eql(12)

  describe "DAY()", ->
    it "returns the value for a given string", ->
      f.get('DAY')('2011-12-08').should.eql(8)

  describe "HOUR()", ->
    it "returns the value for a given string", ->
      f.get('HOUR')('2011-01-01 12:13:14').should.eql(12)

  describe "MINUTE()", ->
    it "returns the value for a given string", ->
      f.get('MINUTE')('2011-01-01 12:13:14').should.eql(13)

  describe "SECOND()", ->
    it "returns the value for a given string", ->
      f.get('SECOND')('2011-01-01 12:13:14').should.eql(14)

  describe "DATE()", ->
    it "parses a time in DB format", ->
      f.get('DATE')('2012-02-21 12:13:14').should.eql(new Date(Date.parse('2012-02-21 12:13:14')))
    it "parses a time in custom format", ->
      f.get('DATE')('21/02/2012@12:13', 'd/M/y@H:m').should.eql(new Date(Date.parse('2012-02-21 12:13:00')))
    it "parses a number as a milliseconds since epoch", ->
      f.get('DATE')(1234567890).should.eql(new Date(1234567890))

  describe "STRFTIME()", ->
    it "formats a date", ->
      f.get('STRFTIME')('2012-02-21 12:13:14').should.eql('2012-02-21 12:13:14')
    it "formats a date with custom format", ->
      f.get('STRFTIME')('2012-02-21 12:13:14', 'MMM').should.eql('Feb')

describe "User Defined Functions", ->
  it "allows adding a user defined function to a context", ->
    ctx = river.createContext()
    ctx.addFunction('ECHO', (x) -> x)
    q = ctx.addQuery "SELECT ECHO(true) AS foo FROM data"
    q.on('insert', expectUpdate({foo:true}))
    ctx.push('data', a:1)

