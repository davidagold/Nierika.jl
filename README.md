# Nierika

[![Build Status](https://travis-ci.org/davidagold/Nierika.jl.svg?branch=master)](https://travis-ci.org/davidagold/Nierika.jl)

SQLite3 Databases
=================
This package contains an experimental design of a data management interface for Julia. It uses SQLite3 as the data management backend and provides an API for querying against a SQLite3 database as well as a means of storing the results of a given query in an in-memory Julia structure called a `Table`. I've lifted essentially all of the Julia interface with SQLite3's C API, as well as the design of the `DB` and `Stmt` types from Jacob Quinn's [SQLite.jl package](https://github.com/quinnj/SQLite.jl).

### Connect to `.db` files via `DB` objects
One can connect to a SQLite3 `.db` file by passing the filename to the `DB` constructor:

```julia
using Nierika
db = DB("db/test.db")
```
Doing so returns a `DB` object, which represents the connection to the `.db` file. All SQL interactions with a SQLite3 database are conducted with reference to a `DB` object. 

In particular, one can use the `query` function to query against a SQLite3 database. To do so, one passes a `DB` object to specify which database is being queried and a string of SQL code: 
```julia
julia> query(db, "select * from person")
Cursor with columns (id, first_name, last_name, age)
CURRENT: 0, Zed, Shaw, 37
INFO: status: 100
```
`query` will always return a `Cursor` object as in the example above. A `Cursor` is an abstraction of the set of rows the query returns as results. A `Cursor` returned from `query` shows information about the names of the columns contained in the result set, information about the current row it "highlights" and the status of the query ("100" means there are more rows to be returned). One can step through the rows using the `step!` method and reset the cursor to the beginning of the result set using the `reset!` method:

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

### Querying API

I am developing experimental methods that make unorthodox use of anonymous functions in order to efface the use of SQL as the querying engine. These methods allow one to query against a `DB` connection via an API that "compiles" to SQL code which is then prepared and executed against the database:
```julia
julia> ab = DB("db/ab.db")
Nierika.DB("db/ab.db",Ptr{Void} @0x00007f874fee4ce0,0)

julia> curs = select(ab, "ab") do
           where(id < 10)
       end
Cursor with columns (id, A, B)
CURRENT: 1, 0.846708563674236, 0.350119432137953
INFO: status: 100
```
Just as with `query`, the `select` method will always return a `Cursor` representing the results of the generated SQL query.

This approach allows query instructions to be lazily accumulated, parsed, and then translated into appropriate SQL. Moreover, the means by which the anonymous function communicates the instructions to `select` does not actually involve running the anonymous function, which is just a vessel of unexecuted code. Rather, `select` extracts as an `Expr` object the body of the anonymous function generated by the `do` block syntax and parses this `Expr` object in order to extract in turn the arguments passed to `where`. This allows for significant flexibility and license in designing the API; one can easily render valid SQL from something like the following:
```julia
julia> curs = select(ab, "ab") do
           where(id < 10, A > .5, B < .5)
       end
Cursor with columns (id, A, B)
CURRENT: 1, 0.846708563674236, 0.350119432137953
INFO: status: 100
```
The primary disadvantage to this approach is that it allows users to interact with columns in a SQLite3 database as though they were actual Julia objects. It's not clear to me whether the ability to generate SQL without "coding in strings" is worth this dissemblance. A similar effect could be achieved by requiring the user to pass, say, the string `"id < 10"` to `where`, which could in that case be an implemented function that actually gets called. However, this approach offers slightly less opportunities for leveraging the structure of `Expr` objects naturally produced by Julia's parser. 

`Table`s
========
Finally, this package also experiments with means of materializing the results represented by a `Cursor` as an in-memory `Table` object:
```julia
julia> tab = select(ab, "ab") do
           where(id < 10)
       end |> Table
9x3 Table with columns
 (id, A, B):
 1  0.846709  0.350119 
 2  0.793645  0.302815 
 3  0.894549  0.578471 
 4  0.880194  0.417208 
 5  0.75912   0.368796 
 6  0.420532  0.814181 
 7  0.212199  0.2416   
 8  0.415272  0.446328 
 9  0.98619   0.0757917
```
In the example above the `Cursor` that is returned from `select` is piped straight into the `Table` constructor. In general, one can always create a `Table` of results from a query against a SQLite3 database by calling `Table` on the `Cursor` returned by the query.

`Table` objects differ significantly in their implementation than comparable Julia tabular data structures such as `Matrix` and `DataFrame`. Constructing a `Table` assigns at the top-level of the invoking namespace the names of each column in the respective results set to a `Nierika.Column{T}` object:

```julia
julia> id
Column{Int64}
```
The type parameter `T` designates the type of values returned by indexing into that column:
```
julia> tab[1, id]
1
```
This allows for type-certain indexing in the sense that the return type of indexing into a `Table` with a row number and column name can be detected at JIT-compile time:

```julia
julia> function f(tab)
           x = 0.0
           for i in 1:nrows(tab)
               x += tab[i, A]
           end
           x
       end
f (generic function with 1 method)

julia> f(tab)
6.20841020470337

julia> @code_warntype f(tab)
Variables:
  tab::Nierika.Table
  x::Float64
  #s24::Int64
  i::Int64

Body:
  begin  # none, line 2:
      x = 0.0 # line 3:
      GenSym(2) = (top(getfield))(tab::Nierika.Table,:nrows)::Int64
      GenSym(0) = $(Expr(:new, UnitRange{Int64}, 1, :(((top(getfield))(Base.Intrinsics,:select_value)::I)((Base.sle_int)(1,GenSym(2))::Bool,GenSym(2),(Base.box)(Int64,(Base.sub_int)(1,1))::Int64)::Int64)))
      #s24 = (top(getfield))(GenSym(0),:start)::Int64
      unless (Base.box)(Base.Bool,(Base.not_int)(#s24::Int64 === (Base.box)(Base.Int,(Base.add_int)((top(getfield))(GenSym(0),:stop)::Int64,1)::Any)::Int64::Bool)::Any)::Bool goto 1
      2: 
      GenSym(3) = #s24::Int64
      GenSym(4) = (Base.box)(Base.Int,(Base.add_int)(#s24::Int64,1)::Any)::Int64
      i = GenSym(3)
      #s24 = GenSym(4) # line 4:
      x = (Base.box)(Base.Float64,(Base.add_float)(x::Float64,(Base.arrayref)((Base.arrayref)((top(getfield))(Main.A,:cols)::Array{Array{Float64,1},1},(Base.box)(Int64,(Base.zext_int)(Int64,(top(getfield))(tab::Nierika.Table,:id)::UInt16)::Any)::Int64)::Array{Float64,1},i::Int64)::Float64)::Any)::Float64
      3: 
      unless (Base.box)(Base.Bool,(Base.not_int)((Base.box)(Base.Bool,(Base.not_int)(#s24::Int64 === (Base.box)(Base.Int,(Base.add_int)((top(getfield))(GenSym(0),:stop)::Int64,1)::Any)::Int64::Bool)::Any)::Bool)::Any)::Bool goto 2
      1: 
      0:  # line 6:
      return x::Float64
  end::Float64
```

Another significant difference between a `Table` and a `DataFrame` concerns the storage of the column values. In a `Table`, the column values are actually stored in the `Column` object itself:
```julia
julia> fieldnames(A)
2-element Array{Symbol,1}:
 :colsymb
 :cols   

julia> typeof(A.cols)
Array{Array{Float64,1},1}

julia> A.cols
1-element Array{Array{Float64,1},1}:
 [0.8467085636742357,0.7936449645683268,0.8945488096599519,0.8801940859970245,0.7591203532454374,0.42053172612130907,0.21219929867544884,0.4152722096581114,0.9861901931035237]
```
Each `Table` is assigned a `UInt16` `id` upon construction. Indexing into a `tab::Table` with an row number `i` and column name `colname` reduces to indexing into the `i`th entry of the `Vector{T}` stored at `colname.cols[tab.id]`, as can be seen from the respective definition of `Base.getindex`:

```julia
function Base.getindex{T}(tab::Table, i::Int, column::Column{T})
    return column.cols[tab.id][i]
end
```

Apart from type-certain indexing, another fun advantage of this approach is the ability to emulate "environment reification" by declaring a global "environment id" which can be modified within a function. In general, attempting to index into a `Column` incurs an error: 
```julia
julia> A[1]
ERROR: BoundsError: attempt to access 1-element Array{Array{Float64,1},1}:
 [0.8467085636742357,0.7936449645683268,0.8945488096599519,0.8801940859970245,0.7591203532454374,0.42053172612130907,0.21219929867544884,0.4152722096581114,0.9861901931035237]
  at index [0]
 in getindex at /Users/David/.julia/v0.4/Nierika/src/table.jl:131
```
 
However, one can use the `with` function to "reify" a `Table` "environment" by setting the value of the environment id to the `id` field of a given `Table`:

```julia
julia> with(tab) do
           x = 0.0
           for i in 1:length(A)
               x += A[i]
           end
           x
       end
6.20841020470337
```

`with` will actually execute the anonymous function passed to it, so this syntax, while handy, will incur the performance penalties currently endemic to anonymous functions:

```julia
julia> @time with(tab) do
           x = 0.0
           for i in 1:length(A)
               x += A[i]
           end
           x
       end
  0.007184 seconds (2.42 k allocations: 116.061 KB)
6.20841020470337
```

However, one is free to write a method for a generic function as though a reified `Table` environment were present and then pass the name of that function, along with any arguments, to `with` after the `Table` argument:

```julia
julia> function f(offs::Int)
           x = 0.0
           for i in offs:length(A)
               x += A[i]
           end
           x
       end
f (generic function with 1 method)

julia> with(tab, f, 1)
6.20841020470337
```

Doing so allows one to avoid the performance penalty incurred by use of the anonymous function:
```julia
julia> @time with(tab, f, 1)
  0.000006 seconds (5 allocations: 176 bytes)
6.20841020470337
```

### Discussion of `Table` design

I have thus far identified primary disadvantages of the above design for an in-memory Julia table type:

1. The scheme relies on assigning names in the caller's global namespace (by means of `eval`, though I don't think the use of `eval` per se is necessarily objectionable here).
2. Storing columnar data across disparate objects may worsen performance for row-oriented operations due to issues of memory layout.
3. Different tabular data sets can be represented in the same global namespace as `Table`s only if columns with shared names contain elements of a common type.

I don't know whether or not the above outweigh the advantages of the scheme, i.e. type-certain column-based indexing and environment reification. I believe that the largest drawback is number 1 above. Number 2 is important, but there has been talk of offering a distinct type that would be better suited to row-based operations. If such a type were implemented, then it would be reasonable to sacrifice row-oriented performance in a column-oriented data type if the advantages were considerable. Number 3 seems like it ought to be fairly easy to accommodate in practice. I would further argue (at least prima facie) that if columns from distinct tables carry distinct enough information such that the element types of the columns are distinct, then one is probably better off selecting different names for the columns in any case.
