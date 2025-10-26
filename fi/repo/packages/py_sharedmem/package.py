# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack_repo.builtin.build_systems.python import PythonPackage
from spack.package import *


class PySharedmem(PythonPackage):
    """A different flavor of multiprocessing in Python"""

    homepage = "https://github.com/rainwoodman/sharedmem"
    pypi = "sharedmem/sharedmem-0.3.8.tar.gz"

    version("0.3.8", sha256="c654a6bee2e2f35c82e6cc8b6c262fcabd378f5ba11ac9ef71530f8dabb8e2f7")

    depends_on("py-setuptools", type="build")

    depends_on("py-numpy", type=("build", "run"))
