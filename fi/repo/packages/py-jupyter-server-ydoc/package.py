# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.package import *


class PyJupyterServerYdoc(PythonPackage):
    """A Jupyter Server Extension Providing Y Documents."""

    homepage = "https://github.com/jupyterlab/jupyter-collaboration"
    pypi = "jupyter_server_ydoc/jupyter_server_ydoc-0.8.0.tar.gz"

    version("0.8.0", sha256="a6fe125091792d16c962cc3720c950c2b87fcc8c3ecf0c54c84e9a20b814526c")

    depends_on("python@3.7:", type=("build", "run"))

    depends_on("py-hatchling@0.25:", type="build")

    depends_on("py-jupyter-ydoc@0.2.0:0.3", type=("build", "run"))
    depends_on("py-ypy-websocket@0.8.2:0.8", type=("build", "run"))
    depends_on("py-jupyter-server-fileid@0.6.0:0", type=("build", "run"))
