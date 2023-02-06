from spack.package import *


class PyHealpy(PythonPackage):
    """healpy is a Python package to handle pixelated data on the sphere.
    
    This version links against the healpix package in the FI repo, rather
    than spack's healpix-cxx.
    """

    homepage = "https://healpy.readthedocs.io/"
    pypi = "healpy/healpy-1.16.2.tar.gz"

    version("1.16.2", sha256="b7b9433152ff297f88fc5cc1277402a3346ff833e0fb7e026330dfac454de480")

    depends_on("py-setuptools@3.2:", type="build")
    depends_on("py-cython", type="build")
    depends_on("py-numpy", type=("build","run"))
    depends_on("healpix", type=("build","link","run"))
