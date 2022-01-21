# Copyright 2013-2020 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack import *
import os

class Disbatch(PythonPackage):
    """Distributed processing of a batch of tasks"""

    homepage = "https://github.com/flatironinstitute/disBatch"
    url      = "https://github.com/flatironinstitute/disBatch/archive/refs/tags/1.4.tar.gz"
    git      = "https://github.com/flatironinstitute/disBatch.git"

    version('2.0', sha256='8a510e6b392491b48c2a03f558a50df71738631d89ccaece7de117d62743e25f')
    version('1.4', sha256='ce3a1079f895ddc0029cd21db3a5f4bf07602392a7587bdf99e4e04834e91516')

    depends_on('py-setuptools', type='build', when='@2:')
    depends_on('py-kvsstcp', type='run')
    patch('2.0-noretiregpu.patch', when='@2.0')

    @run_after('install')
    def create_symlink(self):
        if self.spec.satisfies('@1'):
            script_source = os.path.join(self.prefix.bin, 'disBatch.py')
            script_dest = os.path.join(self.prefix.bin, 'disBatch')
            os.symlink(script_source, script_dest)

            script = Executable(script_source)
            script('--fix-paths')
