from spack.package import *
import spack.pkg.builtin.py_pycuda as builtin

class PyPycuda(builtin.PyPycuda):

    version("2022.2.2",
            sha256="cd92e7246bb45ac3452955a110714112674cdf3b4a9e2f4ff25a4159c684e6bb",
    )
    depends_on("cuda@:11", when="@:2022.2.0")
