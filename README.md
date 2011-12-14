River
=====

River is designed for running efficient queries over unbounded streams of data. At this point it's an experimental playground and should be treated as such.

In many ways you can conceptually think of River as a reverse database. Rather than storing data and then issuing queries over it, in River you create queries and then push data through them. Queries are written in a familiar SQL-like language which supports transforming, filtering, aggregating and merging data sources.

River is written in 100% coffee-script and currently targets the node.js runtime. There is no technical reason why it wouldn't be possible for the code to run purely in a web browser.

If you are after a heavy weight, production ready system please see the Esper project. If however you want something thats hackable, easy to install and simple to use then you might want to give River a go.

    npm install -g river

It's still early days for River and the code is in flux but if your feeling brave then the current public API (from coffeescript) looks something like this...

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
    ctx.removeQuery(query.id)


Currently Working Things
------------------------
* `SELECT * FROM data` - selects
* `SELECT a, b FROM data` - select fields
* `SELECT a AS b FROM data` - select aliases
* `SELECT a.b.c AS d FROM data` - select nested properties
* `SELECT * FROM data WHERE a = 1 AND b > 5` - where conditions
* `SELECT * FROM data LIMIT 5` - limits
* `SELECT DISTINCT a FROM data` - row level distinct
* `SELECT SUM(a) FROM data` - aggregate functions
* `SELECT a, SUM(b) FROM data GROUP BY a` - grouped aggregates
* `SELECT MAX(a) FROM data.win:length(10)` - length windows (last 10 events)
* `SELECT a, b, MIN(c) FROM data.win:time(60) GROUP BY a, b` - time windows (last 60 seconds)
* `SELECT a, SUM(b) AS s FROM data.win:time(60) GROUP BY a HAVING s > 2` - having conditions
* `SELECT a, SUM(b) AS s FROM data GROUP BY a HAVING s > 2` - unbounded having
* `SELECT d.foo FROM (SELECT foo FROM data) d` - aliased sub-selects
* `SELECT * FROM a JOIN b ON a.id = b.id` - inner joins
* `SELECT * FROM a UNION ALL SELECT * FROM b` - union's (currently only `union all`)


Supported Functions
-------------------
Aggregates: `AVG`, `COUNT`, `SUM`, `MIN`, `MAX`

Standard: `ABS`, `CEIL`, `CONCAT`, `FLOOR`, `IF`, `LENGTH`, `LOG`, `LOWER`, `ROUND`, `SUBSTR`, `UPPER`, `UNESCAPE`


Metadata
--------
All objects inserted get decorated with some metadata. This gets stored in a key called '_' and currently looks something like the following.

    { ts: new Date(), src: 'mystream', uuid: '8188540d-418c-49f2-a231-d4dc86490f18' }


User Defined Functions (UDFs)
-----------------------------
For security reasons River queries cannot execute arbitrary JavaScript however it is possible to extend functionality by writing UDFs. These can be useful for performing custom data parsing or more complex logic. Below is an example of a simple UDF...

    ctx = river.createContext()
    ctx.addFunction('SQUARE', (v) -> v * v )
    ctx.addQuery('SELECT SQUARE(2) FROM data')


Planned
-------
* Time batching - table.batch:time(secs) so that queries can be run over batches of time rather than sliding windows.
* Errors - Query syntax errors are caught by the Grammer but logical errors aren't currently handled.
* Time functions - unix_timestamp(d), date(d), strftime(d, fmt), year(d), month(d), day(d), hour(d), minute(d), second(d) - where d is date/string/number

Wishlist
--------
* Pattern Matching - Support a syntax which allows describing patterns through time maybe like [a -> b -> c].
* Views - Allow Queries to be aliased as views and then used by other queries.
* Partitions - Come up with a way to describe logical data partitions so multiple nodes/cores can handle different events.
* HA Server Wrapper - Wrap River in a network server so that it can be used remotely.
* Persistence - Maybe look at ways to store data out of process.


Command Line Tools
------------------
River ships with 2 simple command line tools `river-csv` and `river-zmq` these are useful for doing little on the fly data queries. They work like so...

* `river-csv myfile.csv "SELECT * FROM file"` - expects a path to a CSV file with headers followed by a query, runs the query against the file and emits a new CSV file on stdout.
* `river-zmq tcp://server:port "SELECT * FROM channel" [i|r|ir]` - Requires ZeroMQ to be installed along with the node zmq package. Expects a zmq publisher socket address followed by a query to run. Emits events as JSON to stdout. An optional 3 argument can be used to specify if you would like to get results from the 'insert' stream (default), 'remove' stream, or both - use the flags 'i', 'r' or 'ir' respectively.


Known Issues
------------
* syntax checking is pretty much non existent so doing silly things can cause silly errors.
* Having clauses only work with aliased columns not in place aggregation functions.
* There is currently no support for OUTER joins.
* Some queries, specifically unwindowed JOIN's, can cause memory leaks.


Optimisations
-------------
* generating group keys using JSON.stringify is probably very sub-optimal
* multiple queries in a context over the same stream windows could share events
* queries with sub-selects might be able to share common data
* JOINs have their own data structures. Could they share with repeaters to avoid duplicate objects?
* JOINs use a loop in all cases but for equality joins (a.id = b.id) we could maintain an index.
* JOINs are probably sub optimal in almost every way.

