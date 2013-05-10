river = require('../lib/river')

ctx = river.createContext()

# ctx.addFunction 'FOO', (x) -> 'FOO'

query = ctx.addQuery "SELECT * FROM random.win:length(10) WHERE n > 0.59999 AND n < 0.6"
query.on 'insert', (newValues) -> console.log('NEW', newValues)
query.on 'remove', (oldValues) -> console.log('OLD', oldValues)

loop
  ctx.push 'random', n: Math.random()

