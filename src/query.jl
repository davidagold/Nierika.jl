
function Base.select(f, db::DB, table::String, sel::String="*")
    select_sql = "SELECT $sel FROM $table"
    # extract body of f as Expr object
    ast = Base.uncompressed_ast(f.code)
    e = ast.args[3]
    # extract arguments from call to `where`
    # NOTE: `where` serves only as a parsing landmark; it has no implementation
    clauses = parse_where(e)
    where_sql = " WHERE"
    for (i, clause) in enumerate(clauses)
        i > 1 ? where_sql = where_sql * " AND $clause" :
                where_sql = where_sql * " $clause"
    end
    res_sql = select_sql * where_sql
    return Cursor(Stmt(db, res_sql))
end

parse_where(e) = nothing
function parse_where(e::Expr)
    e = de_global(e) # preprocess by converting GlobalRefs to Symbols
    if (e.head == :call) & (e.args[1] == :where)
        res = e.args[2:end]
    else
        for arg in e.args
            res = parse_where(arg)
        end
    end
    return res
end

de_global(e) = e
de_global(g::GlobalRef) = g.name
function de_global(e::Expr)
    return Expr(e.head, [ de_global(arg) for arg in e.args ]...)
end
