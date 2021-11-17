whatis("Use modules build release from nixpack @GIT@ @DATE@")
setenv("MODULEPATH_BASE", "@MODS@")
prepend_path("MODULEPATH", "@MODS@/Core")
add_property("lmod","sticky")
