from spack_repo.builtin.build_systems.python import PythonPackage
from spack.package import *


class PyPyslurm(PythonPackage):
    """multiplicatively convolutional fast integral transforms"""

    homepage = "https://github.com/PySlurm/pyslurm"
    url = "https://github.com/PySlurm/pyslurm/archive/refs/tags/v24.11.0.tar.gz"
    git = "https://github.com/PySlurm/pyslurm"

    version("26.05.x", branch="26.05.x", commit="6242fadde394ee3f00f5f96ac4fa4a05881db8b6")
    version("24.11.x", branch="24.11.x", commit="2adb2da8b5a1ca5d1b94d94858dd4c406f9f2f07")
    version("24.11.0", sha256="77d97c42bf3639f4babdfcbaa7e674351d974e10d85a7d0015cafd342b15f769")

    depends_on("py-setuptools", type="build")
    depends_on("slurm", type=("build", "run"))
    depends_on("py-cython", type="build")
