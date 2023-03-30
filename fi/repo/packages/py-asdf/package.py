# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.package import *


class PyAsdf(PythonPackage):
    """ ASDF (Advanced Scientific Data Format) is a next generation interchange format for scientific data
    """

    homepage = "https://asdf.readthedocs.io/"
    pypi = "asdf/asdf-2.14.4.tar.gz"

    version("2.14.4", sha256="d1251a9d85ec83437ddddeb205d32381a04ab1240520750189a1d07ee8e91129")
    
    variant("lz4", default=True, description="Enable lz4 compression")

    depends_on("py-setuptools@60:", type="build")
    depends_on("py-setuptools-scm@3.4: +toml", type="build")

    depends_on("py-asdf-standard@1.0.1:", type=("build", "run"))
    depends_on("py-asdf-transform-schemas@0.3:", type=("build", "run"))
    depends_on("py-asdf-unit-schemas@0.1:", type=("build", "run"))
    depends_on("py-importlib-metadata@4.11.4:", type=("build", "run"))
    depends_on("py-importlib-resources@3:", type=("build", "run"), when='python@:3.8')
    depends_on("py-jmespath@0.6.2:", type=("build", "run"))
    depends_on("py-jsonschema@4.0.1:4.17", type=("build", "run"))
    depends_on("py-numpy@1.20:", type=("build", "run"))
    depends_on("py-numpy@1.20:1.24", type=("build", "run"), when='python@:3.8')
    depends_on("py-packaging@19:", type=("build", "run"))
    depends_on("py-pyyaml@5.4.1:", type=("build", "run"))
    depends_on("py-semantic-version@2.8:", type=("build", "run"))
    depends_on('py-lz4@0.10:', when='+lz4', type=("build", "run"))
