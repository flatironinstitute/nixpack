# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack_repo.builtin.build_systems.python import PythonPackage
from spack.package import *


class PyEtuples(PythonPackage):
    """ Python S-expression emulation using tuple-like objects."""

    homepage = "https://github.com/pythological/etuples"
    pypi = "etuples/etuples-0.3.9.tar.gz"

    version("0.3.9", sha256="a474e586683d8ba8d842ba29305005ceed1c08371a4b4b0e0e232527137e5ea3")

    depends_on("python@3.8:", type=("build", "run"))

    depends_on("py-setuptools", type="build")

    depends_on("py-cons", type=("build", "run"))
    depends_on("py-multipledispatch", type=("build", "run"))
