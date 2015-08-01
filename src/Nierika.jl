module Nierika

# using NullableArrays

export  DB, Stmt, Cursor, Table,

        # methods
        colnames,
        nrows,
        query,
        reset!,
        results,
        step!,
        where

include("../deps/deps.jl")
include("SQLite_consts.jl")
include("SQLite_utils.jl")
include("SQLite_api.jl")
include("db.jl")
include("cursor.jl")
include("table.jl")
include("show.jl")

end # module
