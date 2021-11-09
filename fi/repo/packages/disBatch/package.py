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

    version('1.4', sha256='ce3a1079f895ddc0029cd21db3a5f4bf07602392a7587bdf99e4e04834e91516', preferred=True)
    version('2.0-rc1', sha256='d95bcfdb23d5652cd35714e5aaf71d66dc1f39d4486c814567ad80daec4e8484')
    version('2.0-rc2', sha256='6646cd1492644d5bbacd17207228e41591a5f1c46fc8eceadc1639e7ec0bb108')
    version('2.0-rc3', sha256='641f37bdc7c3b3cc2be50e1e0388e133affc77eee416517921740981bb178c9f')
    version('2.0-pip', branch='kvsstcp-pip-dep')

    depends_on('py-setuptools', type='build', when='@2.0-pip')
    depends_on('py-kvsstcp', type='run')

    @run_after('install')
    def create_symlink(self):
        if not self.spec.satisfies('@2.0-pip'):
            script_source = os.path.join(self.prefix.bin, 'disBatch.py')
            script_dest = os.path.join(self.prefix.bin, 'disBatch')
            os.symlink(script_source, script_dest)

        if self.spec.satisfies('@1'):
            script = Executable(script_source)
            script('--fix-paths')
