# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.package import *

import spack.pkg.builtin.py_jupyterhub as builtin


class PyJupyterhub(builtin.PyJupyterhub):

    version("3.1.1", sha256="bfdbc55d7cd29ed2b2c84d2fc7943ad13efdfc4a77740519c5dad1079ff75953")

    depends_on("py-entrypoints", when="@1.0.0:2", type=("build", "run"))
    depends_on("py-importlib_metadata@3.6:", when="python@:3.9")
    depends_on("py-packaging")
