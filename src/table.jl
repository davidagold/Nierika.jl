type Table{C<:Tuple} <: AbstractArray{Any, 2}
    columns::C
    colnames::Vector{UTF8String}
end

Base.size(tab::Table) = (length(tab.columns[1]), length(tab.columns))
Base.ndims(tab::Table) = 2

Base.linearindexing(tab::Table) = Base.LinearSlow()

function Base.getindex(tab::Table, i::Int)
    sub = ind2sub(size(tab), i)
    getindex(tab, sub...)
end

@inline function Base.getindex(tab::Table, i::Int, j::Int)
    return tab.columns[j][i]
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

function Base.convert{T}(::Type{Table}, curs::Cursor{T})
    n = curs.ncols
    columns = tuple([ T.parameters[i]() for i in 1:curs.ncols ]...)
    colnames = curs.cols
    res = Table{T}(columns, colnames)
    stmt = curs.stmt
    status = curs.status
    coltyps = [ eltype(arrtyp) for arrtyp in T.parameters ]
    while status == 100
        i = 1
        for coltyp in coltyps
            push!(res.columns[i], sqlite3_get(coltyp, curs.stmt, i))
            i += 1
        end
        status = execute!(stmt)
    end
    curs.status = status
    return res
end
