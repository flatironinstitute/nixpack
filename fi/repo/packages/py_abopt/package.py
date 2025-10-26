# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack_repo.builtin.build_systems.python import PythonPackage
from spack.package import *


class PyAbopt(PythonPackage):
    """abopt (ABstract OPTimizer) - optimization of generic numerical models"""

    homepage = "https://github.com/bccp/abopt"

    version("0.0.15-16-g1a74289",
        url='https://github.com/bccp/abopt/tarball/1a74289a6901a2b6768bdd9c3834fa5f235eb660',
        sha256="90deb03f1f5522f1e51b32612a2b499cef9c59306885f9b16815cdc2da92a0cc",
    )

    depends_on("py-setuptools", type="build")

    depends_on("py-numpy", type=("build", "run"))
    # scipy.optimize was refactored in 1.8
    depends_on("py-scipy@:1.7", type=("build", "run"))
