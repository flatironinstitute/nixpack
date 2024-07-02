import spack.pkg.builtin.lmod as builtin

class Lmod(builtin.Lmod):
    patch("no-sys-tcl.patch")
    version("8.7.43", sha256="d3fc792d9ca4243ef5a3128894b8da40414f06f9b9ea68bc4b37c4ebb90bd41f")

    def configure_args(self):
        args = super().configure_args()
        args.append('--with-availExtensions=no')
        args.append('--with-cachedLoads=yes')
        return args
