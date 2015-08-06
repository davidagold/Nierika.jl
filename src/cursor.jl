type Cursor <: IO
    stmt::Stmt
    colnames::Vector{UTF8String}
    coltypes::Vector{DataType}
    status::Cint

    function Cursor(stmt::Stmt)
        status = Nierika.execute!(stmt)
        ncols::Int = sqlite3_column_count(stmt.handle)
        colnames = get_colnames(stmt, ncols)
        coltypes = get_coltypes(stmt, ncols)
        return new(stmt, colnames, coltypes, status)
    end
end

function get_colnames(stmt::Stmt, ncols=sqlite3_column_count(stmt.handle))
    colnames = [ utf8(sqlite3_column_name(stmt.handle, i-1)) for i in 1:ncols ]
end

function get_coltypes(stmt::Stmt, ncols::Int)
    types = Array{DataType, 1}()
    for i in 1:ncols
        typ = sqlite3_types[sqlite3_column_type(stmt.handle, i-1)]
        push!(types, typ)
    end
    return types
end

Base.close(curs::Cursor) = close(curs.stmt)

reset!(stmt::Stmt) = sqlite3_reset(stmt.handle)
function reset!(curs::Cursor)
    reset!(curs.stmt)
    curs.status = execute!(curs.stmt)
    return curs
end

ncols(curs::Cursor) = length(curs.colnames)

function Base.eof(curs::Cursor)
    (curs.status == SQLITE_DONE || curs.status == SQLITE_ROW) || sqliteerror(curs.stmt.db)
    return curs.status == SQLITE_DONE
end

function Base.readline(curs::Cursor, delim::Union{Char,ByteString}=", ", buf::IOBuffer=IOBuffer())
    eof(curs) && return ""
    n = ncols(curs)
    for i = 1:n
        val = sqlite3_column_text(curs.stmt.handle, i-1)
        val != C_NULL && write(buf, bytestring(val))
        write(buf, ifelse(i == n, '\n', delim))
    end
    return takebuf_string(buf)
end

function step!(curs::Cursor)
    curs.status = execute!(curs.stmt)
    return curs
end

query(db::DB, sql::String) = Cursor(Stmt(db, sql))
function query(sql::String)
    actuality.actualized ? Cursor(Stmt(actuality.db, sql)) : error()
end

function delim_res(curs::Cursor; delim=',', buf::IOBuffer=IOBuffer())
    n = ncols(curs)
    while curs.status == 100
        for i = 1:n
            val = sqlite3_column_text(curs.stmt.handle, i-1)
            val != C_NULL && write(buf, bytestring(val))
            write(buf, ifelse(i == n, '\n', delim))
        end
        step!(curs)
    end
    return seekstart(buf)
end

function results(curs::Cursor)
    return readdlm(delim_res(curs), ',', '\n')
end
