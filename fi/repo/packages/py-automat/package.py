# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.package import *


class PyAutomat(PythonPackage):
    """Self-service finite-state machines for the programmer on the go."""

    homepage = "https://github.com/glyph/Automat"
    pypi = "Automat/Automat-20.2.0.tar.gz"

    version("22.10.0", sha256="e56beb84edad19dcc11d30e8d9b895f75deeb5ef5e96b84a467066b3b84bb04e")

    depends_on("py-setuptools", type="build")
    depends_on("py-setuptools-scm", type="build")

    depends_on("py-attrs@19.2.0:", type=("build", "run"))
    depends_on("py-six", type=("build", "run"))
