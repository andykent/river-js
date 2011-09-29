river = require('../lib/river')

ctx = river.createContext()

ctx.addQuery "SELECT * FROM random WHERE n > 0.599 AND n < 0.6", 
  (newValues) -> console.log(newValues)

loop
  ctx.push 'random', n: Math.random()

