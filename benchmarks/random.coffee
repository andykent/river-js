iterations = 1000000

river = require('../lib/river')

start = new Date()

ctx = river.createContext()

ctx.addQuery "SELECT * FROM random WHERE n > 0.599 AND n < 0.6", (newValues) -> null

endInit = new Date()

initTime = endInit.getTime() - start.getTime()

console.log("#{initTime} milliseconds to initialize context & query.")

startIts = new Date()

ctx.push('random', n: Math.random()) for i in [1..iterations]

end = new Date()

ms = end.getTime() - startIts.getTime()

console.log("#{Math.round(iterations/ms)} events per millisecond.")