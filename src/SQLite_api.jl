
function sqlite3_errmsg()
    return ccall( (:sqlite3_errmsg, sqlite3_lib),
                  Ptr{Uint8}, () )
end

function sqlite3_errmsg(db::Ptr{Void})
    @NULLCHECK db
    return ccall( (:sqlite3_errmsg, sqlite3_lib),
                  Ptr{Uint8}, (Ptr{Void},), db )
end

function sqlite3_open(file::AbstractString, handle::Vector{Ptr{Void}})
    return ccall( (:sqlite3_open, sqlite3_lib),
                  Cint, (Ptr{Uint8}, Ptr{Void}),
                  file, handle )
end

function sqlite3_open16(file::UTF16String, handle::Array{Ptr{Void},1})
    return ccall( (:sqlite3_open16, sqlite3_lib),
                  Cint, (Ptr{Uint16}, Ptr{Void}),
                  file, handle )
end

function sqlite3_close(handle::Ptr{Void})
    @NULLCHECK handle
    return ccall( (:sqlite3_close, sqlite3_lib),
                  Cint, (Ptr{Void},), handle )
end

function sqlite3_close_v2(handle::Ptr{Void})
    @NULLCHECK handle
    try
        return ccall( (:sqlite3_close_v2, sqlite3_lib),
                      Cint, (Ptr{Void},), handle )
    catch
        # Older versions of the library don't have this, abort to other close
        warn("sqlite3_close_v2 not available.")
        sqlite3_close(handle)
    end
end

function sqlite3_next_stmt(db::Ptr{Void}, stmt::Ptr{Void})
    @NULLCHECK db
    return ccall( (:sqlite3_next_stmt, sqlite3_lib),
                  Ptr{Void}, (Ptr{Void}, Ptr{Void}),
                  db, stmt )
end

function sqlite3_prepare_v2(handle::Ptr{Void}, query::AbstractString,
                            stmt::Array{Ptr{Void},1}, unused::Array{Ptr{Void},1})
    @NULLCHECK handle
    return ccall( (:sqlite3_prepare_v2, sqlite3_lib),
                  Cint, (Ptr{Void}, Ptr{Uint8}, Cint, Ptr{Void}, Ptr{Void}),
                  handle, query, sizeof(query), stmt, unused )
end

function sqlite3_prepare16_v2(handle::Ptr{Void}, query::AbstractString,
                              stmt::Array{Ptr{Void},1}, unused::Array{Ptr{Void},1})
    @NULLCHECK handle
    return ccall( (:sqlite3_prepare16_v2, sqlite3_lib),
                  Cint, (Ptr{Void}, Ptr{Uint16}, Cint, Ptr{Void}, Ptr{Void}),
                  handle, query, sizeof(query), stmt, unused )
end

function sqlite3_finalize(stmt::Ptr{Void})
    @NULLCHECK stmt
    return ccall( (:sqlite3_finalize, sqlite3_lib),
                  Cint, (Ptr{Void},), stmt )
end

function sqlite3_step(stmt::Ptr{Void})
    @NULLCHECK stmt
    return ccall( (:sqlite3_step, sqlite3_lib),
                  Cint, (Ptr{Void},), stmt )
end

function sqlite3_column_count(stmt::Ptr{Void})
    @NULLCHECK stmt
    return ccall( (:sqlite3_column_count, sqlite3_lib),
                  Cint, (Ptr{Void},), stmt )
end

function sqlite3_column_type(stmt::Ptr{Void},col::Int)
    @NULLCHECK stmt
    return ccall( (:sqlite3_column_type, sqlite3_lib),
                  Cint, (Ptr{Void}, Cint),
                  stmt, col )
end

function sqlite3_column_name(stmt::Ptr{Void},n::Int)
    @NULLCHECK stmt
    return ccall( (:sqlite3_column_name, sqlite3_lib),
                  Ptr{Uint8}, (Ptr{Void}, Cint),
                  stmt, n )
end


function sqlite3_reset(stmt::Ptr{Void})
    @NULLCHECK stmt
    return ccall( (:sqlite3_reset, sqlite3_lib),
                  Cint, (Ptr{Void},), stmt )
end


function sqlite3_column_blob(stmt::Ptr{Void},col::Int)
    @NULLCHECK stmt
    return ccall( (:sqlite3_column_blob, sqlite3_lib),
                  Ptr{Void}, (Ptr{Void}, Cint),
                  stmt, col )
end
function sqlite3_column_bytes(stmt::Ptr{Void},col::Int)
    @NULLCHECK stmt
    return ccall( (:sqlite3_column_bytes, sqlite3_lib),
                  Cint, (Ptr{Void}, Cint),
                  stmt, col )
end
function sqlite3_column_bytes16(stmt::Ptr{Void},col::Int)
    @NULLCHECK stmt
    return ccall( (:sqlite3_column_bytes16, sqlite3_lib),
                  Cint, (Ptr{Void}, Cint),
                  stmt, col )
end
@inline function sqlite3_column_double(stmt::Ptr{Void},col::Int)
    @NULLCHECK stmt
    return ccall( (:sqlite3_column_double, sqlite3_lib),
                  Cdouble, (Ptr{Void}, Cint),
                  stmt, col )
end
function sqlite3_column_int(stmt::Ptr{Void},col::Int)
    @NULLCHECK stmt
    return ccall( (:sqlite3_column_int, sqlite3_lib),
                  Cint, (Ptr{Void}, Cint),
                  stmt, col )
end
@inline function sqlite3_column_int64(stmt::Ptr{Void},col::Int)
    @NULLCHECK stmt
    return ccall( (:sqlite3_column_int64, sqlite3_lib),
                  Clonglong, (Ptr{Void}, Cint),
                  stmt, col )
end
function sqlite3_column_text(stmt::Ptr{Void},col::Int)
    @NULLCHECK stmt
    return ccall( (:sqlite3_column_text, sqlite3_lib),
                  Ptr{Uint8}, (Ptr{Void}, Cint),
                  stmt, col )
end
function sqlite3_column_text16(stmt::Ptr{Void},col::Int)
    @NULLCHECK stmt
    return ccall( (:sqlite3_column_text16, sqlite3_lib),
                  Ptr{Void}, (Ptr{Void}, Cint),
                  stmt, col )
end

# SQLITE_API void sqlite3_result_double(sqlite3_context*, double);
function sqlite3_result_double(context::Ptr{Void},value::Float64)
    return ccall( (:sqlite3_result_double, sqlite3_lib),
                  Void, (Ptr{Void}, Float64),
                  context, value )
end
# SQLITE_API void sqlite3_result_error(sqlite3_context*, const char*, int)
function sqlite3_result_error(context::Ptr{Void},msg::AbstractString)
    return ccall( (:sqlite3_result_error, sqlite3_lib),
                  Void, (Ptr{Void}, Ptr{Uint8}, Cint),
                  context, value, sizeof(msg) + 1 )
end
# SQLITE_API void sqlite3_result_error16(sqlite3_context*, const void*, int)
function sqlite3_result_error(context::Ptr{Void},msg::UTF16String)
    return ccall( (:sqlite3_result_error16, sqlite3_lib),
                  Void, (Ptr{Void}, Ptr{Uint16}, Cint),
                  context, value, sizeof(msg) + 1 )
end
# SQLITE_API void sqlite3_result_int(sqlite3_context*, int);
function sqlite3_result_int(context::Ptr{Void},value::Int32)
    return ccall( (:sqlite3_result_int, sqlite3_lib),
                  Void, (Ptr{Void}, Int32),
                  context, value )
end
# SQLITE_API void sqlite3_result_int64(sqlite3_context*, sqlite3_int64);
function sqlite3_result_int64(context::Ptr{Void},value::Int64)
    return ccall( (:sqlite3_result_int64, sqlite3_lib),
                  Void, (Ptr{Void}, Int64),
                  context, value )
end
# SQLITE_API void sqlite3_result_null(sqlite3_context*);
function sqlite3_result_null(context::Ptr{Void})
    return ccall( (:sqlite3_result_null, sqlite3_lib),
                  Void, (Ptr{Void},),
                  context )
end
# SQLITE_API void sqlite3_result_text(sqlite3_context*, const char*, int n, void(*)(void*));
function sqlite3_result_text(context::Ptr{Void},value::AbstractString)
    return ccall( (:sqlite3_result_text, sqlite3_lib),
                  Void, (Ptr{Void}, Ptr{Uint8}, Cint, Ptr{Void}),
                  context, value, sizeof(value) + 1, SQLITE_TRANSIENT )
end
# SQLITE_API void sqlite3_result_text16(sqlite3_context*, const void*, int, void(*)(void*));
function sqlite3_result_text16(context::Ptr{Void},value::UTF16String)
    return ccall( (:sqlite3_result_text, sqlite3_lib),
                  Void, (Ptr{Void}, Ptr{Uint16}, Cint, Ptr{Void}),
                  context, value, sizeof(value) + 1, SQLITE_TRANSIENT )
end
# SQLITE_API void sqlite3_result_blob(sqlite3_context*, const void*, int n, void(*)(void*));
function sqlite3_result_blob(context::Ptr{Void},value)
    return ccall( (:sqlite3_result_blob, sqlite3_lib),
                  Void, (Ptr{Void}, Ptr{Uint8}, Cint,Ptr{Void}),
                  context, value, sizeof(value), SQLITE_TRANSIENT )
end

function sqlite3_initialize()
    return ccall( (:sqlite3_initialize, sqlite3_lib),
        Cint, (),
        )
end
function sqlite3_shutdown()
    return ccall( (:sqlite3_shutdown, sqlite3_lib),
        Cint, (),
        )
end

sqlite3_types = Dict{Int, DataType}(
    1 => Int,
    2 => Float64,
    3 => UTF8String,
    4 => Any,
    5 => Nullable,
)
