# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.package import *


class PyClassylss(PythonPackage):
    """a lightweight Python binding of the CLASS CMB Boltzmann code"""

    homepage = "https://github.com/nickhand/classylss"
    pypi = "classylss/classylss-0.2.9.tar.gz"

    version("0.2.9", sha256="1a8521d2bf9da3d2572245e801e243fcf76f7518b59cbe525a31aa80a884dd86")

    depends_on("py-setuptools", type="build")

    depends_on("py-numpy", type=("build", "run"))
    depends_on("py-cython", type=("build", "run"))
    depends_on("py-six", type=("build", "run"))

    def patch(self):
        # Shouldn't rely on the Cythonized output being portable
        remove('classylss/binding.c')
