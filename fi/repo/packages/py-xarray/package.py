from spack.package import *
import spack.pkg.builtin.py_xarray as builtin

class PyXarray(builtin.PyXarray):

    version("2023.05.0", sha256="318a651f4182b9cecb7d1c57ad0ed9bdaed5f49c43dbb638c0a845b8faf405e8")

    with when("@2023.05.0:"):
        depends_on("python@3.9:", type="build")

        depends_on("py-setuptools@42:", type="build")
        depends_on("py-setuptools-scm@7:", type="build")

        depends_on("py-numpy@1.21:", type=("build", "run"))
        depends_on("py-pandas@1.4:", type=("build", "run"))
        depends_on("py-packaging@21.3:", type=("build", "run"))
