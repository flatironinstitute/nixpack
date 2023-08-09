from spack.package import *
import spack.pkg.builtin.librsvg as builtin

class Librsvg(builtin.Librsvg):

    version("2.56.0", sha256="194b5097d9cd107495f49c291cf0da65ec2b4bb55e5628369751a3f44ba222b3")

    conflicts("rust@1.69:", when="@:2.54.1")  # dep tendril < 0.4.3 conflicts
