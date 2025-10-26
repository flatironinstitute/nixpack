# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack_repo.builtin.build_systems.python import PythonPackage
from spack.package import *


class PyRuntests(PythonPackage):
    """Simple testing of fresh package builds using pytest, with optional mpi4py support"""

    homepage = "https://github.com/bccp/runtests"
    pypi = "runtests/runtests-0.0.28.tar.gz"

    version("0.0.28", sha256="add28a6cbbf4cdcfcabb0a8897f154835b7357c0c502e4a389829d30c2dabee4")

    variant("mpi", default=True, description="MPI support")

    depends_on("py-setuptools", type="build")
    
    depends_on("py-pytest", type=("build", "run"))
    depends_on("py-coverage", type=("build", "run"))
    
    depends_on("mpi", when="+mpi")
    depends_on("py-mpi4py", type=("build", "run"), when="+mpi")
