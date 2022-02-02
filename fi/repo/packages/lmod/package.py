import spack.pkg.builtin.lmod as builtin

class Lmod(builtin.Lmod):
    patch("sticky.patch", when='@:8.5.27')

    def configure_args(self):
        args = super().configure_args()
        args.append('--with-availExtensions=no')
        args.append('--with-cachedLoads=yes')
        return args
