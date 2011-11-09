ENDPOINT = 'http://andykentspam:a1b2c3@stream.twitter.com/1/statuses/sample.json'
USERNAME = 'andykentspam'
PASSWORD = 'a1b2c3'

river = require('../lib/river')

{TwitterNode} = require('twitter-node')

twit = new TwitterNode(user: USERNAME, password: PASSWORD)
twit.action = 'sample'

ctx = river.createContext()

# auth = 'Basic ' + new Buffer(USERNAME + ':' + PASSWORD).toString('base64')

# console.log(auth)

# reqOpts = {
#   host: "stream.twitter.com",
#   port: 443,
#   path: '/1/statuses/sample.json',
#   method: 'GET',
#   headers: {
#     'Host': 'stream.twitter.com',
#     'Authorization': auth,
#     'Accept-Type' : 'application/json',
#     'Content-Type' : 'application/json',
#   }
# }
# 
# https.request reqOpts, (res) ->
#   console.log('BOOM!')
#   res.setEncoding('utf8')
#   console.log("statusCode: ", res.statusCode)
#   console.log("headers: ", res.headers)
#   buffer = ''
#   res.on 'data', (chunk) ->
#     console.log(chunk)
#     buffer += chunk
#     parts = buffer.split("\n")
#     buffer = parts.pop()
#     for part in parts
#       ctx.push('tweets', JSON.parse(part))

twit.addListener 'tweet', (tweet) ->
  console.log(tweet)
  ctx.push('tweets', JSON.parse(tweet))

query = ctx.addQuery "SELECT * FROM tweets"
query.on 'insert', (newValues) -> console.log('NEW', newValues)
query.on 'remove', (oldValues) -> console.log('OLD', oldValues)