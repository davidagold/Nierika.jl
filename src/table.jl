
immutable Table <: AbstractArray{Any, 2}
    columns
    colnames::Vector{UTF8String}

    function Table(curs::Cursor)
        env(curs)
        cols = materialize!(curs)
        return new(cols, curs.colnames)
    end
end

# Base.size(tab::Table) = (length(tab.columns[1]), length(tab.columns))
Base.size(tab::Table) = size(tab.columns)
Base.ndims(tab::Table) = 2
nrows(tab::Table) = size(tab)[1]


Base.linearindexing(tab::Table) = Base.LinearSlow()

function Base.getindex(tab::Table, i::Int)
    sub = ind2sub(size(tab), i)
    getindex(tab, sub...)
end

# @inline function Base.getindex(tab::Table, i::Int, j::Int)
#     return tab.columns[j][i]
# end

@inline function Base.getindex(tab::Table, i::Int, j::Int)
    return tab.columns[i, j]
end

@inline function Base.getindex{T}(tab::Table, i::Int, col::ColName{T})
    return tab.columns[i, col.idx]::T
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
    # return tuple(cols...)
    return hcat(cols...)
end
