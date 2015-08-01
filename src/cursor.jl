type Cursor <: IO
    stmt::Stmt
    colnames::Vector{UTF8String}
    coltypes::Vector{DataType}
    status::Cint
    where::String

    function Cursor(stmt::Stmt, where::String="")
        status = Nierika.execute!(stmt)
        ncols::Int = sqlite3_column_count(stmt.handle)
        colnames = _colnames(stmt, ncols)
        coltypes = _coltypes(stmt, ncols)
        return new(stmt, colnames, coltypes, status, where)
    end
end

immutable ColName{T}
    idx::Int
    colname::UTF8String
end

function env(curs::Cursor)
    # colinds = Vector{ColName}()
    for (i, colname) in enumerate(curs.colnames)
        typ = curs.coltypes[i]
        current = current_module()
        eval(current, :( global const $(symbol(colname)) = Nierika.ColName{$typ}($i, $colname) ))
        # eval(current, :( global const $(symbol(colname)) = Nierika.ColName{$typ}($i) ))
        # push!(colinds, ColName{typ}(i))
    end
    # return colinds
end

function env(colnames, coltypes)
    for (i, colname) in enumerate(colnames)
        typ = coltypes[i]
        current = current_module()
        eval(current, :( global const $(symbol(colname)) = Nierika.ColName{$typ}($i, $colname) ))
    end
end

ncols(curs::Cursor) = length(curs.colnames)

function _colnames(curs::Cursor)
    n = ncols(curs)
    colnames = [ utf8(sqlite3_column_name(curs.stmt.handle, i-1)) for i in 1:n ]
end

function _colnames(stmt::Stmt, ncols=sqlite3_column_count(stmt.handle))
    colnames = [ utf8(sqlite3_column_name(stmt.handle, i-1)) for i in 1:ncols ]
end

function _coltypes(stmt::Stmt, ncols::Int)
    types = Array{DataType, 1}()
    for i in 1:ncols
        typ = sqlite3_types[sqlite3_column_type(stmt.handle, i-1)]
        # push!(types, Vector{typ})
        push!(types, typ)
    end
    return types
end

Base.close(curs::Cursor) = close(curs.stmt)

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
    # curs.status = sqlite3_step(curs.stmt.handle)
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

function restof(curs::Cursor; delim=',', buf::IOBuffer=IOBuffer())
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
    return readdlm(restof(curs), ',', '\n')
end

reset!(stmt::Stmt) = sqlite3_reset(stmt.handle)
function reset!(curs::Cursor)
    reset!(curs.stmt)
    curs.status = execute!(curs.stmt)
    return curs
end

function nrows(curs::Cursor)
    return sqlite3_column_int64(curs.stmt.handle, 0)
end

let safe, buf
    safe = false
    buf = IOBuffer()
    where_buf = IOBuffer()

    global select
    function Base.select(f, db::DB, table::String, sel::String="*")
        safe = true
        write(buf, "select $sel from $table")
        f()
        _where = takebuf_string(where_buf)
        write(buf, _where)
        sql = takebuf_string(buf)
        safe = false
        return Cursor(Stmt(db, sql, table), _where)
        # println(sql)
    end

    function Base.select(f, db::DB, table::String, selection::Vararg{ColName})
        safe = true
        colnames = [ "$(col.colname), " for col in selection ]
        length(selection) == 0 ? _selection = "*" :
                                 _selection = "$(colnames...)"
        write(buf, "SELECT $_selection FROM $table")
        f()
        _where = takebuf_string(where_buf)
        write(buf, _where)
        sql = takebuf_string(buf)
        safe = false
        return Cursor(Stmt(db, sql, table), _where)
    end

    global where
    function where(sql::String)
        safe == true || error()
        write(where_buf, " where $sql")
    end
end

function Base.(:>)(col::ColName, x::Any)
    return "$(col.colname) > $x"
end
