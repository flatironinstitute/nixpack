# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)


from spack.package import *


class PyNbodykit(PythonPackage):
    """ Analysis kit for large-scale structure datasets, the massively parallel way"""

    homepage = "https://nbodykit.readthedocs.io"

    version("0.3.15-40-g376c9d78",
        url='https://www.github.com/bccp/nbodykit/tarball/376c9d78204650afd9af81d148b172804432c02f',
        sha256="2a38ab2dd78893a542997af168bba57794e1916efbd5d436b0507487ae383dc5",
    )

    variant('extras', default=True, description='Install extras')

    depends_on("py-setuptools", type="build")
    depends_on("py-numpy", type=("build", "run"))
    depends_on("py-cython", type=("build", "run"))
    depends_on("mpi")
    depends_on("py-mpi4py", type=("build", "run"))
    depends_on("py-scipy", type=("build", "run"))
    depends_on("py-astropy", type=("build", "run"))
    depends_on("py-pyerfa", type=("build", "run"))
    depends_on("py-six", type=("build", "run"))
    depends_on("py-runtests +mpi", type=("build", "run"))
    depends_on("py-pmesh", type=("build", "run"))
    depends_on("py-kdcount", type=("build", "run"))
    depends_on("py-mpsort", type=("build", "run"))
    depends_on("py-bigfile +mpi", type=("build", "run"))
    depends_on("py-pandas", type=("build", "run"))
    depends_on("py-dask@0.14.2:", type=("build", "run"))
    depends_on("py-cachey", type=("build", "run"))
    depends_on("py-sympy@1.6.2:", type=("build", "run"))
    depends_on("py-numexpr", type=("build", "run"))
    depends_on("py-corrfunc", type=("build", "run"))
    depends_on("py-mcfit", type=("build", "run"))
    depends_on("py-classylss@0.2:", type=("build", "run"))

    depends_on('py-halotools', type=("build", "run"), when='+extras ^python@3.9:')
    depends_on('py-h5py', type=("build", "run"), when='+extras')
    depends_on('py-fitsio', type=("build", "run"), when='+extras')
