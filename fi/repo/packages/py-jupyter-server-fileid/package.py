# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.package import *


class PyJupyterServerFileid(PythonPackage):
    """Jupyter Server extension providing an implementation of the File ID service."""

    homepage = "https://github.com/jupyter-server/jupyter_server_fileid"
    pypi = "jupyter_server_fileid/jupyter_server_fileid-0.9.0.tar.gz"

    version("0.9.0", sha256="171538b7c7d08d11dbc57d4e6da196e0c258e4c2cd29249ef1e032bb423677f8")

    depends_on("python@3.7:", type=("build", "run"))

    depends_on("py-hatchling@1.0:", type="build")

    depends_on("py-jupyter-server@1.15:2", type=("build", "run"))
    depends_on("py-jupyter-events@0.5.0:", type=("build", "run"))
