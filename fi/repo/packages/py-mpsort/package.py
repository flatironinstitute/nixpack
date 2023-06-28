# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.package import *


class PyMpsort(PythonPackage):
    """Massively Parallel Histogram Sort"""

    homepage = "https://github.com/rainwoodman/MP-sort"

    version("0.1.17-56-gea7a5bf",
        url='https://github.com/rainwoodman/MP-sort/tarball/ea7a5bfd24d2fa9fe2de7ede5946f2c6761229b6',
        sha256="d8ead1f88cbaea9aac4d5b67c938ed3ddc611f6ba1577dcc739ad92ed0ec6d89",
    )

    depends_on("py-setuptools", type="build")

    depends_on("py-numpy", type=("build", "run"))
    depends_on("py-cython", type=("build", "run"))
    depends_on("mpi")
    depends_on("py-mpi4py", type=("build", "run"))
