describe "River Public API", ->
  
  it "allows requiring, creating contexts and adding queries", ->
    river = require('../lib/river')
    ctx = river.createContext()
    queryId = ctx.addQuery("SELECT * FROM data")