
# immutable Table{C} # <: AbstractArray{Any, 2}
#     columns::C
#     colnames::Vector{UTF8String}
# end

# function Table(curs::Cursor)
#     env(curs)
#     cols = materialize!(curs)
#     return Table{typeof(cols)}(cols, curs.colnames)
# end

immutable Column{T}
    # idx::Int
    colname::UTF8String
    # col::Dict{Symbol, Vector{T}}
    cols::Vector{Vector{T}}
end

immutable Table <: AbstractArray{Any, 2}
    columns::Vector{Column}
    # id::Symbol
    id::UInt16
    nrows::Int
    # colnames::Vector{UTF8String}

    let count = UInt16(1)
        global Table
        function Table(curs::Cursor)
            cols, nrows = materialize!(curs)
            res = new(Vector{Column}(), count, nrows)
            env!(curs, cols, res)
            count += UInt16(1)
            return res
        end
    end
end


# function env(curs::Cursor)
#     # colinds = Vector{Column}()
#     for (i, colname) in enumerate(curs.colnames)
#         typ = curs.coltypes[i]
#         current = current_module()
#         eval(current, :( global const $(symbol(colname)) = Nierika.Column{$typ}($i, $colname) ))
#         # eval(current, :( global const $(symbol(colname)) = Nierika.Column{$typ}($i) ))
#         # push!(colinds, Column{typ}(i))
#
#     end
#     # return colinds
# end

function env!(curs::Cursor, cols, tab::Table)
    for (i, colname) in enumerate(curs.colnames)
        typ = curs.coltypes[i]
        current = current_module()
        colsymb = symbol(colname)
        _colsymb = Expr(:quote, colsymb)
        _tabid = Expr(:quote, tab.id)
        eval(current, quote
            if !in($_colsymb, names($current))
                # coldict = Dict{Symbol, Array{$typ}}( $_tabid => $(cols[i]) )
                coldict = Vector{$typ}[ $(cols[i]) ]
                # global const $colsymb = Nierika.Column{$typ}($i, $colname, coldict)
                global const $colsymb = Nierika.Column{$typ}($colname, coldict)
            else
                # $colsymb.cols[$_tabid] = $(cols[i])
                push!($colsymb.cols, $(cols[i]))
            end
            push!($(tab.columns), $colsymb)
        end)
    end
end

Base.size(tab::Table) = (nrows(tab), length(tab.columns))
# Base.size(tab::Table) = size(tab.columns)
Base.ndims(tab::Table) = 2
nrows(tab::Table) = tab.nrows


Base.linearindexing(tab::Table) = Base.LinearSlow()

function Base.getindex(tab::Table, i::Int)
    sub = ind2sub(size(tab), i)
    getindex(tab, sub...)
end

@inline function Base.getindex(tab::Table, i::Int, j::Int)
    return tab.columns[j].cols[tab.id][i]
    # return tab.columns[j].cols[1][i]
end

# @inline function Base.getindex(tab::Table, i::Int, j::Int)
#     return tab.columns[i, j]
# end

# @inline function Base.getindex{T}(tab::Table, i::Int, col::Column{T})
#     return tab.columns[i, col.idx]::T
# end

@inline function Base.getindex{T}(tab::Table, i::Int, column::Column{T})
    return column.cols[tab.id][i]
    # return column.cols[1][i]
end

function sqlite3_get(::Type{Int}, stmt, i)
    return sqlite3_column_int64(stmt.handle, i-1)::Int
end

function sqlite3_get(::Type{Float64}, stmt, i)
    return sqlite3_column_double(stmt.handle, i-1)::Float64
end

function sqlite3_get{T<:String}(::Type{T}, stmt, i)
    return bytestring(sqlite3_column_text(stmt.handle, i-1))
end

function sqlite3_get(::Type{Nullable}, stmt, i)
    return "NA"
end

function materialize!(curs::Cursor)
    n = ncols(curs)
    coltypes = curs.coltypes
    cols = [ Array{coltypes[i], 1}() for i in 1:n ]
    stmt = curs.stmt
    status = curs.status
    while status == 100
        i = 1
        for coltyp in coltypes
            push!(cols[i], sqlite3_get(coltyp, curs.stmt, i))
            i += 1
        end
        status = execute!(stmt)
    end
    curs.status = status
    return cols, length(cols[1])
    # return tuple(cols...)
    # return hcat(cols...)
end


# const safety_id = gensym("UNSAFE_ENV")
# const env_id = Symbol[safety_id]
const safety_id = UInt16(0)
const env_id = UInt16[safety_id]

function Base.getindex{T}(column::Column{T}, i::Int)
    return column.cols[env_id[1]][i]
end

Base.length(column::Column) = length(column.cols[env_id[1]])

function with(f::Function, tab::Table)
    env_id[1] = tab.id
    res = f()
    env_id[1] = safety_id
    return res
end

function with(tab::Table, f)
    env_id[1] = tab.id
    res = f()
    env_id[1] = safety_id
    return res
end
