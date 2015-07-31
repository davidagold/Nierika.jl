using BinDeps

@BinDeps.setup

sqlite3_lib = library_dependency("sqlite3_lib",
                                 aliases = ["sqlite3", "sqlite3-64",
                                            "libsqlite3", "libsqlite3-0"])
# @osx_only begin
#     using Homebrew
#     provides(Homebrew.HB, "sqlite", sqlite3_lib, os = :Darwin)
# end

@BinDeps.install [:sqlite3_lib => :sqlite3_lib ]
