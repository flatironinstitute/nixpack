# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack_repo.builtin.build_systems.python import PythonPackage
from spack.package import *


class PyMcfit(PythonPackage):
    """multiplicatively convolutional fast integral transforms"""

    homepage = "https://github.com/eelregit/mcfit"
    pypi = "mcfit/mcfit-0.0.18.tar.gz"

    version("0.0.18", sha256="2d2564b4f511c7101caf1d06947927140ef2068175a42c966d0844c7ddb9914c")

    depends_on("py-setuptools", type="build")

    depends_on("py-numpy", type=("build", "run"))
    depends_on("py-scipy", type=("build", "run"))
    depends_on("py-mpmath", type=("build", "run"))
