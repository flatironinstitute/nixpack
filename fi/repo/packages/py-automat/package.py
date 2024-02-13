from spack.package import *
import spack.pkg.builtin.py_automat


class PyAutomat(spack.pkg.builtin.py_automat.PyAutomat):
    version("22.10.0", sha256="e56beb84edad19dcc11d30e8d9b895f75deeb5ef5e96b84a467066b3b84bb04e")
