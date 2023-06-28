# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.package import *


class PyBigfile(PythonPackage):
    """A reproducible massively parallel IO library for hierarchical data"""

    homepage = "https://github.com/rainwoodman/bigfile"
    pypi = "bigfile/bigfile-0.1.51.tar.gz"

    version("0.1.51", sha256="1fad962defc7a5dff2965025dff9a3efa23594e1c2300de0c9a43940d4717b65")

    variant("mpi", default=True, description="MPI support")

    depends_on("py-setuptools", type="build")

    depends_on("py-cython", type=("build", "run"))
    depends_on("py-numpy", type=("build", "run"))

    depends_on("mpi", when="+mpi")
    depends_on("py-mpi4py", type=("build", "run"), when="+mpi")
