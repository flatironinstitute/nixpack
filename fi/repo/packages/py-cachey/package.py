# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.package import *


class PyCachey(PythonPackage):
    """Caching based on computation time and storage space"""

    homepage = "https://github.com/dask/cachey"
    pypi = "cachey/cachey-0.2.1.tar.gz"

    version("0.2.1", sha256="0310ba8afe52729fa7626325c8d8356a8421c434bf887ac851e58dcf7cf056a6")

    depends_on("py-setuptools", type="build")

    depends_on("py-heapdict", type=("build", "run"))
    
    depends_on("py-pytest", type=("test"))
    depends_on("py-pytest-runner", type=("test"))
