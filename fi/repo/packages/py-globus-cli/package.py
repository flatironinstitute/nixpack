# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.package import *


class PyGlobusCli(PythonPackage):
    """A Command Line Wrapper over the Globus SDK for Python"""

    homepage = "https://github.com/globus/globus-cli"
    pypi = "globus-cli/globus-cli-3.12.0.tar.gz"

    version("3.12.0", sha256="a93abd8583ea10f6df8fae84e17b5b253b9bb7d563fa09f8eaad0c3a3b8e95eb")

    depends_on("python@3.7:", type=("build", "run"))

    depends_on("py-setuptools", type="build")

    depends_on("py-globus-sdk@3.17.0", type=("build", "run"))
    depends_on("py-click@8.0.0:8", type=("build", "run"))
    depends_on("py-jmespath@1.0.1", type=("build", "run"))
    depends_on("py-packaging@17.0:", type=("build", "run"))
    depends_on("py-requests@2.19.1:2", type=("build", "run"))
    # globus-cli specifies py-cryptography@3.3.1:36
    # but says that this just reflects globus-sdk, which has since removed its upper version limit
    depends_on("py-cryptography@3.3.1:", type=("build", "run"))
    depends_on("py-typing-extensions@4.0:", type=("build", "run"), when='python@:3.10')
