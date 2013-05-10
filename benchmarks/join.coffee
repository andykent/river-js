iterations = 100000

river = require('../lib/river')

start = new Date()

ctx = river.createContext()

sql = """
  SELECT * FROM random_1.win:length(1000)
    JOIN random_2.win:length(1000)
    ON random_1.n = random_2.n
"""

ctx.addQuery sql, (newValues) -> null

endInit = new Date()

initTime = endInit.getTime() - start.getTime()

console.log("#{initTime} milliseconds to initialize context & query.")

startIts = new Date()

for i in [1..iterations]
  ctx.push('random_1', n: Math.random())
  ctx.push('random_2', n: Math.random())

end = new Date()

ms = end.getTime() - startIts.getTime()

console.log("#{Math.round(iterations/ms*1000)} events per second.")