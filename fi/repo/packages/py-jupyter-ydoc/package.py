# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.package import *


class PyJupyterYdoc(PythonPackage):
    """Document structures for collaborative editing using Ypy"""

    homepage = "https://github.com/jupyter-server/jupyter_ydoc"
    pypi = "jupyter_ydoc/jupyter_ydoc-1.0.2.tar.gz"

    version("0.2.4", sha256="a3f670a69135e90493ffb91d6788efe2632bf42c6cc42a25f25c2e6eddd55a0e")

    depends_on("python@3.7:", type=("build", "run"))

    depends_on("py-hatchling@1.10.0:", type="build")
    depends_on("py-hatch-nodejs-version", type="build")

    depends_on("py-importlib-metadata@3.6:", type=("build", "run"), when="^python@:3.9")
    depends_on("py-y-py@0.5.3:0.5", type=("build", "run"))
