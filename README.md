# Nierika

[![Build Status](https://travis-ci.org/davidagold/Nierika.jl.svg?branch=master)](https://travis-ci.org/davidagold/Nierika.jl)

This package contains an experimental design of a data management interface for Julia. It uses SQLite3 as the data management backend, allowing users to interact with SQLite3 `.db` files through `DB` objects:

```julia
using Nierika
db = DB("db/test.db")
```
I've lifted essentially all of the Julia interface with SQLite3's C API, as well as the design of the `DB` and `Stmt` types from Jacob Quinn's [SQLite.jl package](https://github.com/quinnj/SQLite.jl).

One can query a SQLite3 database by passing a `DB` object and a string containing SQL code to the `query` method:
```julia
julia> query(db, "select * from person")
Cursor with columns (id, first_name, last_name, age)
CURRENT: 0, Zed, Shaw, 37
INFO: status: 100
```
Doing so returns a `Cursor` object, which is an abstraction of the set of rows the query returns as results. The `Cursor` shows information about the names of the columns contained in the result set, information about the current row it "highlights" and the status of the query ("100" means there are more rows to be returned). One can step through the rows using the `step!` method and reset the cursor to the beginning of the result set using the `reset!` method:
```julia
julia> step!(ans)
Cursor with columns (id, first_name, last_name, age)
CURRENT: 1, David, Gold, 25
INFO: status: 100

julia> reset!(ans)
Cursor with columns (id, first_name, last_name, age)
CURRENT: 0, Zed, Shaw, 37
INFO: status: 100
```
This package also experiments with means of materializing the results represented by a `Cursor` as an in-memory `Table` object:
```julia
julia> Table(ans)
4x4 Table with columns (id, first_name, last_name, age):
 0  "Zed"     "Shaw"     37
 1  "David"   "Gold"     25
 2  "Santa"   "Clause"  400
 3  "Barack"  "Obama"    53
```
Finally, I am also experimenting with developing query methods in Julia in order to efface the use of SQL as the querying engine:
```julia
julia> select(db, "person") do
           where("id > 1")
       end |> Table
2x4 Table with columns (id, first_name, last_name, age):
 2  "Santa"   "Clause"  400
 3  "Barack"  "Obama"    53
 ```
