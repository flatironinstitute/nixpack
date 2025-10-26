# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack_repo.builtin.build_systems.python import PythonPackage
from spack.package import *


class PyCons(PythonPackage):
    """An implementation of Lisp/Scheme-like cons in Python."""

    homepage = "https://github.com/pythological/python-cons"
    pypi = "cons/cons-0.4.5.tar.gz"

    version("0.4.5", sha256="b46b48adb5a5af7f44375da346d926e55a325d4dc12b9add9f20280d3b3742cb")

    depends_on("python@3.6:", type=("build", "run"))

    depends_on("py-setuptools", type="build")
    depends_on("py-logical-unification@0.4.0:", type=("build","run"))
