module Nierika

using NullableArrays

export  Index,
        Table,
        @Table,
        Field,
        Col,
        getrow


include("tables.jl")
include("indexing.jl")
include("primitives.jl")
include("cursor.jl")
include("formula.jl")

end # module
