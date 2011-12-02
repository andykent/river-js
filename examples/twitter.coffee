fs = require('fs')
river = require('../lib/river')

Twitter = require('ntwitter')

twit = new Twitter(JSON.parse(fs.readFileSync(__dirname + '/credentials.json')))

ctx = river.createContext()

twit.stream 'statuses/sample', (stream) ->
  stream.on 'data', (tweet) ->
    ctx.push('tweets', tweet)

# query = ctx.addQuery "SELECT * FROM tweets LIMIT 1"
query = ctx.addQuery "SELECT source, COUNT(1) AS i FROM tweets.win:time(10) GROUP by source HAVING i > 10"

query.on 'insert', (newValues) -> console.log('+', newValues)
# query.on 'remove', (oldValues) -> console.log('-', oldValues)