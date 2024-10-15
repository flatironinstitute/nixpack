import spack.pkg.builtin.lmod as builtin

class Lmod(builtin.Lmod):
    patch("no-sys-tcl.patch")
