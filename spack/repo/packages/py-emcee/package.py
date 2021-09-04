# Copyright 2013-2021 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack import *


class PyEmcee(PythonPackage):
    """emcee is an MIT licensed pure-Python implementation of Goodman & Weare's
    Affine Invariant Markov chain Monte Carlo (MCMC) Ensemble sampler."""

    homepage = "https://github.com/dfm/emcee"
    pypi = "emcee/emcee-3.3.1.tar.gz"

    version('3.1.1', sha256='48ffc6a7f5c51760b7a836056184c7286a9959ef81b45b977b02794f1210fb5c')

    depends_on('py-pip', type='build')
    depends_on('py-numpy', type=('build', 'run'))
