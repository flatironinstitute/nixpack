# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack_repo.builtin.build_systems.python import PythonPackage
from spack.package import *



class PyPmesh(PythonPackage):
    """Particle Mesh in Python"""

    homepage = "https://github.com/rainwoodman/pmesh"

    version("0.1.56-7-g6fe8b2d",
        url='https://github.com/rainwoodman/pmesh/tarball/6fe8b2da4a3fd408517ff16698da0eac05b8cd13',
        sha256="65ab0a89f894f6a41059cc07307c6d98fe0946ae3a3fd45e2b697094f8f3aa5f",
    )

    variant("abopt", default=False, description="Add support for abopt")

    depends_on("c", type="build")
    depends_on("py-setuptools", type="build")
    depends_on("py-cython", type=("build", "run"))
    depends_on("py-numpy", type=("build", "run"))
    depends_on("mpi")
    depends_on("py-mpi4py", type=("build", "run"))
    depends_on("py-mpsort", type=("build", "run"))
    depends_on("py-pfft-python", type=("build", "run"))

    depends_on('py-abopt', type=("build", "run"), when="+abopt")
