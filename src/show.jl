function Base.summary(curs::Cursor)
    colnames = get_colnames(curs.colnames)
    res = "Cursor with columns $colnames"
end

function get_colnames(colnames::Vector{UTF8String})
    n = length(colnames)
    res = "("
    for i in eachindex(colnames)
        i == n ? res = res * "$(colnames[i]))" :
                 res = res * "$(colnames[i]), "
    end
    return res
end

function Base.show(io::IO, curs::Cursor)
    println(io, summary(curs))
    curs.status == 100 ? print(io, "CURRENT: $(readline(curs))") :
    curs.status == 101 && println(io, "No more results to show")
    info("status: ", curs.status)
end

function Base.summary(tab::Table)
    dims = Base.dims2string(size(tab))
    colnames = [ column.colname for column in tab.columns ]
    return "$dims Table with columns\n$colnames"
end

function Base.show(io::IO, tab::Table)
    println(io, summary(table))
    Base.showlimited(io, tab)
end

function Base.show{T}(io::IO, column::Column{T})
    print(io, "Column{$T}")
    # Base.showlimited(io, column.col)
end
