River
=====

River is the successor to Creek it's designed for running efficient queries over unbounded streams of data.

It's still early days for River and the code is in flux but if your feeling brave then the current public interface looks something like this...

    river = require('river')

    # A context is basically a container for one or more queries and one or more streams.
    # you can consider a context to be similar in terms to a DataBase in a traditional RDBMS
    ctx = river.createContext()

    # You can add queries to a context using the addQuery function,
    query = ctx.addQuery( "SELECT foo FROM my_stream.win:time(60) WHERE foo > 2")

    # each query should provide event handlers to be run when data changes
    # there are two types of events that get emitted 'insert' and 'remove'
    # 'insert' events are fired as new data is available that matches your query
    # 'remove' events only get triggered when your query specifies an aggregation or a window.
    query.on 'insert', (record) -> console.log(record)
    query.on 'remove', (record) -> console.log(record)

    # The push function is used to add data to a stream
    # streams can be considered similar to tables in a traditional RDBMS
    # any JS Object can be pushed onto a stream but string keys and primative values are assumed
    ctx.push('my_stream', foo:1, bar:2)
    ctx.push('my_stream', foo:3, bar:4)

    # running queries can be removed using the ID provided by previous calls to addQuery
    # COMING SOON!
    ctx.removeQuery(query.id)


Currently Working Things
------------------------

* `SELECT * FROM data`
* `SELECT a, b FROM data`
* `SELECT a AS b FROM data`
* `SELECT * FROM data WHERE a = 1 AND b > 5`
* `SELECT * FROM data LIMIT 5`
* `SELECT DISTINCT a FROM data`
* `SELECT COUNT(a) FROM data`
* `SELECT MAX(a) FROM data.win:length(10)`
* `SELECT a, b, MIN(c) FROM data.win:time(60) GROUP BY a, b`


Supported Functions
-------------------
Aggregates: `COUNT`, `MIN`, `MAX`
Standard: `ABS`, `CEIL`, `CONCAT`, `FLOOR`, `IF`, `LENGTH`, `LOG`, `LOWER`, `ROUND`, `SUBSTR`, `UPPER`, `UNESCAPE`


Work In Progress
----------------

* `SELECT a, COUNT(b) FROM data.win:time(60) GROUP BY a HAVING COUNT(b) > 2`
* `SELECT a, COUNT(b) FROM data GROUP BY a`
* `SELECT a, COUNT(b) FROM data GROUP BY a HAVING COUNT(b) > 2`


Planned
-------

* Time batching
* Sub selects
* Unions
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
* `river-zmq tcp://server:port "SELECT * FROM channel" [i|r|ir]` - Requires ZeroMQ to be installed along with the node zmq package. Expects a zmq publisher socket address followed by a  query to run. Emits events as JSON to stdout. An optional 3 argument can be used to specify if you would like to get results from the 'insert' stream (default), 'remove' stream, or both - use the flags 'i', 'r' or 'ir' respectively.


Known Issues
------------

* Nested functions don't work everywhere
* Math doesn't really work anywhere
* Groups don't work over windowed queries


Optimisations
-------------

* Groups current cause a memory leak as old group objects aren't removed after falling out of time windows
* generating group keys using JSON.stringify is probably very sub-optimal
* Storage could be optimised by pruning records to only include the fields required by the query on input
* multiple queries in a context over the same stream windows could share events



