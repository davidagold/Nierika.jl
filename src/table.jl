
immutable Column{T}
    colsymb::Symbol
    cols::Vector{Vector{T}}
end

Base.length(column::Column) = length(column.cols[env_id[1]])
Base.setindex!(columm::Column, x, i) = error()

immutable Table <: AbstractArray{Any, 2}
    columns::Vector{Tuple{Symbol, Column}}
    id::UInt16
    nrows::Int

    let count = UInt16(1)
        global Table
        function Table(curs::Cursor)
            cols, nrows, colsymbs = materialize!(curs)
            # res = new(Vector{Column}(), count, nrows)
            res = new(Vector{Tuple{Symbol, Column}}(), count, nrows)
            env!(res, cols, colsymbs, curs.coltypes)
            count += UInt16(1)
            return res
        end
    end
end

# Table construction utilities

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
    colsymbs = [ symbol(curs.colnames[i]) for i in 1:n ]
    res = Dict{Symbol, Array}([ colsymbs[i] => cols[i] for i in 1:n ])
    return res, length(cols[1]), colsymbs
end

# Keep track of all column names we have generated for a given module
let registry = Dict{Module, Vector{Symbol}}()
    global env!
    function env!(tab::Table, cols, colsymbs, coltypes)
        current = current_module()
        current_cols = get!(registry, current, Vector{Symbol}())
        for (i, colsymb) in enumerate(colsymbs)
            _colsymb = Expr(:quote, colsymb)
            typ = coltypes[i]
            # If the current module does not have the column name in its namespace,
            # create a Column{typ} with said name and add the name to the registry
            eval(current, quote
                if !in($_colsymb, names($current))
                    colvec = Vector{$typ}[]
                    global const $colsymb = Nierika.Column{$typ}($_colsymb, colvec)
                    push!($current_cols, $_colsymb)
                end
            end)
        end
        current_cols = registry[current]
        # For each Column name in the registry, if that name belongs to `tab`,
        # then push to that Column's `cols` field the appropriate Vector{typ};
        # otherwise, push any empty vector.
        for (i, colsymb) in enumerate(current_cols)
            _colsymb = Expr(:quote, colsymb)
            if in(colsymb, colsymbs)
                eval(current, quote
                    push!($colsymb.cols, $cols[$_colsymb])
                    # $tab.columns[$_colsymb] = $colsymb
                    push!($tab.columns, ($_colsymb, $colsymb))
                end)
            else
                eval(current, quote
                    push!($colsymb.cols, [])
                end)
            end
        end
    end
end # let registry

# primitives and indexing

Base.size(tab::Table) = (nrows(tab), length(tab.columns))
Base.ndims(tab::Table) = 2
nrows(tab::Table) = tab.nrows

Base.linearindexing(tab::Table) = Base.LinearSlow()

function Base.getindex(tab::Table, i::Int)
    sub = ind2sub(size(tab), i)
    getindex(tab, sub...)
end

@inline function Base.getindex(tab::Table, i::Int, j::Int)
    return tab.columns[j][2].cols[tab.id][i]
end

@inline function Base.getindex{T}(tab::Table, i::Int, column::Column{T})
    return column.cols[tab.id][i]
end

const safety_id = UInt16(0)
const env_id = UInt16[safety_id]

@inline function Base.getindex{T}(column::Column{T}, i::Int)
    return column.cols[env_id[1]][i]
end

# "environment reification"

function with(f::Function, tab::Table, args...)
    env_id[1] = tab.id
    res = f(args...)
    env_id[1] = safety_id
    return res
end

function with(tab::Table, f, args...)
    env_id[1] = tab.id
    res = f(args...)
    env_id[1] = safety_id
    return res
end
