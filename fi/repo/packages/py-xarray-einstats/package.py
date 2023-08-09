# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.package import *


class PyXarrayEinstats(PythonPackage):
    """Stats, linear algebra and einops for xarray"""

    homepage = "https://einstats.python.arviz.org"
    pypi = "xarray-einstats/xarray-einstats-0.5.1.tar.gz"

    version("0.5.1", sha256="45283e8b471ac54ac2957bc14e311f681b84dabc50c85959b9931e6f5cc60bcb")

    depends_on("python@3.9:", type=("build", "run"))

    depends_on("py-flit-core@3.4:3", type="build")

    depends_on("py-numpy@1.21:", type=("build", "run"))
    depends_on("py-scipy@1.7:", type=("build", "run"))
    depends_on("py-xarray@2022.09.0:", type=("build", "run"))
