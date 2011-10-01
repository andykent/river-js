River
=====

River is the successor to Creek it's designed for running efficient queries over unbounded streams of data.

There's not a lot here yet but the the following example will probably work...

    river = require('river')

    # A context is basically a container for one or more queries and one or more streams.
    # you can consider a context to be similar in terms to a DataBase in a traditional RDBMS
    ctx = river.createContext()

    # You can add queries to a context using the addQuery function,
    # each query should also provide a callback to be run when data changes
    # the callback gets to objects, the newValues that have appeared and the oldValues that have gone
    queryId = ctx.addQuery( "SELECT foo FROM my_stream WHERE foo > 2", (newValues, oldValues) -> console.log(arguments) )

    # The push function is used to add data to a stream
    # streams can be considered similar to tables in a traditional RDBMS
    # any JS Object can be pushed onto a stream but string keys and primative values are assumed
    ctx.push('my_stream', foo:1, bar:2)
    ctx.push('my_stream', foo:3, bar:4)

    # running queries can be removed using the ID provided by previous calls to addQuery
    # 
    ctx.removeQuery(queryId)


Currently Working Things
------------------------

* `SELECT * FROM data`
* `SELECT a, b FROM data`
* `SELECT a AS b FROM data`
* `SELECT * FROM data WHERE a = 1 AND b > 5`
* `SELECT * FROM data LIMIT 5`
* `SELECT DISTINCT a FROM data`
* `SELECT COUNT(a) FROM data`


Supported Functions
-------------------
Aggregates: `COUNT`
Standard: `LENGTH`


Work In Progress
----------------

* Other functions `MIN`, `MAX`, `CONCAT` etc...
* `SELECT a, COUNT(b) FROM data GROUP BY a`
* `SELECT a, COUNT(b) FROM data GROUP BY a HAVING COUNT(b) > 2`


Planned
-------

* Time windowing
* Event count windowing
* Time batching
* Sub selects
* Joins


Wishlist
--------

* Views
* Persistence
* HA Server


Command Line Tools
------------------

River ships with 2 simple command line tools `river-csv` and `river-zmq` these are useful for doing little on the fly data queries. They work like so...

* `river-csv myfile.csv "SELECT * FROM file"` - expects a path to a CSV file with headers followed by a query, runs the query against the file and emits a new CSV file on stdout.
* `river-zmq tcp://server:port "SELECT * FROM channel"` - Requires ZeroMQ to be installed along with the node zmq package. Expects a zmq publisher socket address followed by a  query to run. Emits NEW/OLD events as JSON to stdout.

