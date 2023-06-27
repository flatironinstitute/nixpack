# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.package import *


class PyPytensor(PythonPackage):
    """ PyTensor is a fork of Aesara -- a Python library for defining, optimizing, and
    efficiently evaluating mathematical expressions involving multi-dimensional arrays.
    """

    homepage = "https://pytensor.readthedocs.io/"
    pypi = "pytensor/pytensor-2.12.2.tar.gz"

    version("2.12.2", sha256="ee4f1a4aefda269a5a399b7bc90da75b263cf019ba881f30cc5881e5886e9230")

    depends_on("python@3.8:", type=("build", "run"))

    depends_on("py-setuptools@48.0.0:", type=("build", "run"))
    depends_on("py-cython", type="build")
    depends_on("py-numpy@1.17.0:", type=("build", "run"))
    depends_on("py-versioneer@0.28 +toml", type="build")

    depends_on("py-scipy@0.14:", type=("build", "run"))
    depends_on("py-filelock", type=("build", "run"))
    depends_on("py-etuples", type=("build", "run"))
    depends_on("py-logical-unification", type=("build", "run"))
    depends_on("py-minikanren", type=("build", "run"))
    depends_on("py-cons", type=("build", "run"))
    depends_on("py-typing-extensions", type=("build", "run"))
