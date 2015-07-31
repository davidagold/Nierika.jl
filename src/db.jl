type DB
    file::UTF8String
    handle::Ptr{Void}
    changes::Int

    function DB(f::UTF8String)
        handle = [C_NULL]
        f = isempty(f) ? f : expanduser(f)
        if @OK sqliteopen(f, handle)
            db = new(f, handle[1], 0)
            # register(db, regexp, nargs=2)
            finalizer(db, x -> sqlite3_close(handle[1]))
            return db
        else # error
            sqlite3_close(handle[1])
            sqliteerror()
        end
    end
end

function DB(f::AbstractString; actualize::Bool=false)
    res = DB(utf8(f))
    actualize && actualize!(res)
    return res
end
DB() = DB(":memory:")

Base.close(db::DB) = sqlite3_close_v2(db.handle)

type World
    actualized::Bool
    db::DB

    World() = new(false)
end

const actuality = World()

function actualize!(db::DB)
    actuality.db = db
    actuality.actualized = true;
end

type Stmt
    db::DB
    handle::Ptr{Void}
    sql::String
    table::String

    function Stmt(db::DB, sql::AbstractString, table::String="")
        handle = [C_NULL]
        sqliteprepare(db, sql, handle, [C_NULL])
        stmt = new(db, handle[1], sql, table)
        finalizer(stmt, x -> sqlite3_finalize(handle[1]))
        return stmt
    end
end

Base.close(stmt::Stmt) = sqlite3_finalize(stmt.handle)

function sqliteprepare(db, sql, stmt, null)
    @CHECK db sqlite3_prepare_v2(db.handle, utf8(sql), stmt, null)
end

function execute!(stmt::Stmt)
    r = sqlite3_step(stmt.handle)
    if r == SQLITE_DONE
        sqlite3_reset(stmt.handle)
    elseif r != SQLITE_ROW
        sqliteerror(stmt.db)
    end
    return r
end
