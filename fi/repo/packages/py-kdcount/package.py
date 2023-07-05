# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.package import *


class PyKdcount(PythonPackage):
    """ KDTree for low dimensional spatial indexing, a Python extension"""

    homepage = "https://github.com/rainwoodman/kdcount"

    version("0.3.29-13-g6e6ddfc",
        url='https://github.com/rainwoodman/kdcount/tarball/6e6ddfcd17621ef0e42a4ea7360e87613ddbee33',
        sha256="f4cc85cbb61a0b2f50f1162b113b12f5c4d5b159e6c9ecd15d0ae4ad6fa17838",
    )

    variant('sharedmem', default=True, description='Use sharedmem')

    depends_on("py-setuptools", type="build")

    depends_on("py-numpy", type=("build", "run"))
    depends_on("py-cython", type=("build", "run"))
    depends_on("py-sharedmem", type=("build", "run"), when='+sharedmem')
