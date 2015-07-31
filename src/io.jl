function csv(db::DB, f::String, table::String)
    _begin = `sqlite3 $(db.file)`
    _mode = `sqlite3 .mode csv`
    _import = `sqlite3 .import $f $table`
    _save = `sqlite3 .save $(db.file)`
    run(pipe(_begin, _mode, _import, _save))
end

function csv(f::String, table::String)
    cmd = `sqlite3 $(actuality.db.file) .mode csv .import $f $table`
    run(cmd)
end
