# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.package import *


class PyAiofiles(PythonPackage):
    """aiofiles is an Apache2 licensed library, written in Python, for
    handling local disk files in asyncio applications."""

    homepage = "https://github.com/Tinche/aiofiles"
    pypi = "aiofiles/aiofiles-0.5.0.tar.gz"

    version("22.1.0", sha256="9107f1ca0b2a5553987a94a3c9959fe5b491fdf731389aa5b7b1bd0733e32de6")
    version("0.5.0", sha256="98e6bcfd1b50f97db4980e182ddd509b7cc35909e903a8fe50d8849e02d815af")

    depends_on("py-setuptools", type="build", when="@0.5")

    depends_on("python@3.7:", type=("build", "run"), when="@22:")

    depends_on("py-poetry-core@1.0.0:", type="build", when="@22:")
