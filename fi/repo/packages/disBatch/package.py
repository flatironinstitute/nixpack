# Copyright 2013-2020 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.package import *
import os

class Disbatch(PythonPackage):
    """Distributed processing of a batch of tasks"""

    homepage = "https://github.com/flatironinstitute/disBatch"
    git      = "https://github.com/flatironinstitute/disBatch.git"

    version('2.5', tag='2.5', commit='abee40342f1ecb5e9b801744d860b5b1414d4b2c', submodules=True)
    version('2.0', tag='2.0', submodules=True)
    version('1.4', tag='1.4', submodules=True)

    depends_on('py-setuptools', type='build', when='@2:')
    depends_on('py-kvsstcp', type='run', when='@:2.0')

    @run_after('install')
    def create_symlink(self):
        if self.spec.satisfies('@1'):
            script_source = os.path.join(self.prefix.bin, 'disBatch.py')
            script_dest = os.path.join(self.prefix.bin, 'disBatch')
            os.symlink(script_source, script_dest)

            script = Executable(script_source)
            script('--fix-paths')
