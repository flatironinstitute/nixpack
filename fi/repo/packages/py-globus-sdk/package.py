# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)


from spack.package import *
import spack.pkg.builtin.py_globus_sdk as builtin


class PyGlobusSdk(builtin.PyGlobusSdk):
    """
    Globus SDK for Python
    """

    version("3.17.0", sha256="d850b2a88463a0437024734e0a78a49ef896530ec94263b54614ca701960794c")

    depends_on("python@3.7:", type=("build", "run"), when='@3.18:')
    depends_on("py-typing-extensions@4.0:", when="python@:3.9")
