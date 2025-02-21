import spack.pkg.builtin.python
from spack import *


class Python(spack.pkg.builtin.python.Python):
    def configure_args(self):
        args: list[str] = super().configure_args()

        def filtersys(arg):
            if arg.startswith(("CPPFLAGS=", "LDFLAGS=")):
                lhs, rhs = arg.split("=")
                rhs = " ".join(
                    [x for x in rhs.split() if not x.startswith(("-I/usr/", "-L/usr/"))]
                )
                arg = f"{lhs}={rhs}"
            return arg

        args = list(map(filtersys, args))

        return args
