River
=====

River is the successor to Creek it's designed for running efficient queries over unbounded streams of data.

There's nothing here yet but the goal is to support the following example syntax...

    river = require('river')

    # A context is basically a container for one or more queries and one or more streams.
    # you can consider a context to be similar in terms to a DataBase in a traditional RDBMS
    ctx = river.createContext()

    # You can add queries to a context using the addQuery function,
    # each query should also provide a callback to be run when data changes
    # the callback gets to objects, the newValues that have appeared and the oldValues that have gone
    queryId = ctx.addQuery( "SELECT foo FROM my_stream:window(1 sec)", (newValues, oldValues) -> console.log(arguments) )

    # The push function is used to add data to a stream
    # streams can be considered similar to tables in a traditional RDBMS
    # any JS Object can be pushed onto a stream but string keys and primative values are assumed
    ctx.push('my_stream', foo:1, bar:2)
    ctx.push('my_stream', foo:3, bar:4)

    # running queries can be removed using the ID provided by previous calls to addQuery
    # 
    ctx.removeQuery(queryId)

    ctx.destroy()
