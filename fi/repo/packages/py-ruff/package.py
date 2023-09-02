# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)


from spack.package import *


class PyRuff(PythonPackage):
    """An extremely fast Python linter, written in Rust."""

    homepage = "https://beta.ruff.rs/docs/"
    pypi = "ruff/ruff-0.0.272.tar.gz"

    version("0.0.286", sha256="f1e9d169cce81a384a26ee5bb8c919fe9ae88255f39a1a69fd1ebab233a85ed2")
    version("0.0.272", sha256="273a01dc8c3c4fd4c2af7ea7a67c8d39bb09bce466e640dd170034da75d14cab")

    depends_on("python@3.7:", type=("build", "run"))

    depends_on("py-maturin@1", type="build")
    
    depends_on("rust@1.70:", when="@0.0.272:")
    depends_on("rust@1.71:", when="@0.0.286:")
