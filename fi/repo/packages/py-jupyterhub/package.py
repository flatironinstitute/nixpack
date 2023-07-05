# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.package import *

import spack.pkg.builtin.py_jupyterhub as builtin


class PyJupyterhub(builtin.PyJupyterhub):

    version("4.0.1", sha256="8e283ff59e5c4016712077d2549ed74acd915a32836fe00218678a8781bd7ede")
    version("3.1.1", sha256="bfdbc55d7cd29ed2b2c84d2fc7943ad13efdfc4a77740519c5dad1079ff75953")

    depends_on("py-entrypoints", when="@1.0.0:2", type=("build", "run"))
    depends_on("py-importlib_metadata@3.6:", when="python@:3.9")
    depends_on("py-packaging")

    depends_on("py-setuptools@61:", type=("build",), when="@4:")
    depends_on("py-setuptools-scm", type=("build",), when="@4:")
    depends_on("py-sqlalchemy@1.4:", type=("build", "run"), when="@4:")
