# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.package import *


class PyDedalus(PythonPackage):
    """A flexible framework for solving PDEs with modern spectral methods."""

    homepage = "https://dedalus-project.readthedocs.io"

    version("3.2302-dev",
        url="https://www.github.com/DedalusProject/dedalus/tarball/5b52e29ab6d5d832de61d412c09e08aa5718e1ab",
        sha256="fb4788f849a08a575f2033236eef0d35fb1629561ae8a16969dbbc146411cf1e",
    )

    version("2.2207.3",
        url="https://pypi.org/packages/source/d/dedalus/dedalus-2.2207.3.tar.gz",
        sha256="549dc967cfb649ae08c9f891389d74488f34c17850b95127a3f9ed51c758c9ad",
    )

    depends_on("py-setuptools", type="build")

    depends_on("py-cython@0.22:", type=("build", "run"))
    depends_on("mpi")
    depends_on("py-mpi4py@2.0.0:", type=("build", "run"))
    depends_on("py-numpy@1.20.0:", type=("build", "run"))
    depends_on("py-docopt", type=("build", "run"))
    depends_on("py-h5py@2.10.0:", type=("build", "run"), when="@:2")
    depends_on("py-h5py@3:", type=("build", "run"), when="@3:")
    depends_on("py-matplotlib", type=("build", "run"))
    depends_on("py-py", type=("build", "run"))
    depends_on("py-pytest", type=("build", "run"))
    depends_on("py-pytest-benchmark", type=("build", "run"))
    depends_on("py-pytest-cov", type=("build", "run"))
    depends_on("py-pytest-parallel", type=("build", "run"))
    depends_on("py-scipy@1.4.0:", type=("build", "run"))
    depends_on("py-numexpr", type=("build", "run"), when="@3:")
    depends_on("py-xarray", type=("build", "run"), when="@3:")
    depends_on("fftw@3: +mpi", type=("build", "run"))

    def setup_build_environment(self, env):
        env.set('FFTW_PATH', self.spec['fftw'].prefix)
        env.set('MPI_PATH', self.spec['mpi'].prefix)
