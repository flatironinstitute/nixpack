# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.package import *


class PyYPy(PythonPackage):
    """Python bindings for the Y-CRDT built from yrs (Rust)"""

    homepage = "https://github.com/y-crdt/ypy"
    pypi = "y_py/y_py-0.5.9.tar.gz"

    version("0.5.9", sha256="50cfa0532bcee27edb8c64743b49570e28bb76a00cd384ead1d84b6f052d9368")

    depends_on("py-maturin@0.14", type="build")
