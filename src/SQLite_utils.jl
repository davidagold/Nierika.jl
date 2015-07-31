macro OK(func)
    return :($func == SQLITE_OK)
end

macro CHECK(db,ex)
    return quote
        if !(@OK $ex)
            sqliteerror($db)
        end
        SQLITE_OK
    end
end

macro NULLCHECK(ptr)
    return quote
        if $ptr == C_NULL
            error()
        end
    end
end

regexp(r::AbstractString, s::AbstractString) = ismatch(Regex(r), s)

sqliteopen(file,handle) = sqlite3_open(file, handle)
sqliteopen(file::UTF16String,handle) = sqlite3_open16(file, handle)

type SQLiteException <: Exception
    msg::AbstractString
end
sqliteerror() = throw(SQLiteException(bytestring(sqlite3_errmsg())))
sqliteerror(db) = throw(SQLiteException(bytestring(sqlite3_errmsg(db.handle))))
