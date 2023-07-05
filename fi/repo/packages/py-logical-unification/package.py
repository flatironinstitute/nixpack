# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.package import *


class PyLogicalUnification(PythonPackage):
    """Straightforward unification in Python that's extensible via generic functions."""

    homepage = "https://github.com/pythological/unification/"
    pypi = "logical-unification/logical-unification-0.4.6.tar.gz"

    version("0.4.6", sha256="908435123f8a106fa4dcf9bf1b75c7beb309fa2bbecf277868af8f1c212650a0")

    depends_on("python@3.6:", type=("build", "run"))

    depends_on("py-setuptools", type="build")

    depends_on("py-multipledispatch", type=("build","run"))
    depends_on("py-toolz", type=("build","run"))
