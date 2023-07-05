# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.package import *


class PyHalotools(PythonPackage):
    """Python package for studying large scale structure, cosmology, and galaxy
    evolution using N-body simulations and halo models"""

    homepage = "https://halotools.readthedocs.io/"
    pypi = "halotools/halotools-0.8.1.tar.gz"

    version("0.8.1", sha256="defc8913f06e2bf69ca33b4167eb61fa5277810a5daedd1b84846186061a78e3")

    variant("extras", default=True, description="Install the 'all' set of extras")

    depends_on("python@3.9:", type=("build", "run"))

    depends_on("py-setuptools@42:", type="build")
    depends_on("py-setuptools-scm", type="build")
    # depends_on("py-oldest-supported-numpy", type="build")
    depends_on("py-cython@0.29.32", type="build")
    depends_on("py-extension-helpers", type="build")

    depends_on("py-astropy", type=("build", "run"))
    depends_on("py-numpy", type=("build", "run"))
    depends_on("py-scipy", type=("build", "run"))
    depends_on("py-requests", type=("build", "run"))
    depends_on("py-beautifulsoup4", type=("build", "run"))
    depends_on("py-cython", type=("build", "run"))

    depends_on("py-h5py", type=("build", "run"), when="+extras")
