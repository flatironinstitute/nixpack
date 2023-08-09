from spack.package import *
import spack.pkg.builtin.py_h5netcdf as builtin

class PyH5netcdf(builtin.PyH5netcdf):

    version("1.2.0", sha256="7f6b2733bde06ea2575b79a6450d9bd5c38918ff4cb2a355bf22bbe8c86c6bcf")

    with when("@1.2.0:"):
        depends_on("python@3.9:", type=("build", "run"))
        
        depends_on("py-setuptools@42:", type=("build",))
        depends_on("py-setuptools-scm@7.0: +toml", type=("build",))

        depends_on("py-h5py", type=("build", "run"))
        depends_on("py-packaging", type=("build", "run"))
