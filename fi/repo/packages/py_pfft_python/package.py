# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack_repo.builtin.build_systems.python import PythonPackage
from spack.package import *


class PyPfftPython(PythonPackage):
    """python binding of PFFT, a massively parallel FFT library"""

    homepage = "https://github.com/rainwoodman/pfft-python"
    pypi = "pfft-python/pfft_python-0.1.21.tar.gz"

    version("0.1.24", sha256="9c6adb258f34ff81a0a3800ab0f08976d4b8de8980d927503df544808fbd6471")

    depends_on("c", type="build")
    depends_on("py-setuptools", type="build")
    
    depends_on("py-numpy", type=("build", "run"))
    depends_on("mpi")
    # Need to use the bundled, patched pfft (which in turn bundles FFTW)
    # depends_on("pfft", type=("build", "link", "run"))
    depends_on("py-mpi4py", type=("build", "run"))
    depends_on("py-cython", type=("build", "run"))

    def patch(self):
        # removing cythonized file from sdist
        remove('pfft/core.c')

        if 'sse' not in self.spec.target:
            filter_file(r"optimize=.*sse.*",
                        "optimize=''",
                        'setup.py',
            )
