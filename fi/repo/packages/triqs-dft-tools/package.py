from spack import *

class TriqsDftTools(CMakePackage):
    """TRIQS: continuous-time hybridization-expansion solver"""

    homepage = "https://triqs.github.io/dft_tools"
    url      = "https://github.com/TRIQS/dft_tools/releases/download/3.0.0/dft_tools-3.0.0.tar.gz"

    version('3.0.0', sha256='646d1d2dca5cf6ad90e18d0706124f701aa94ec39c5236d8fcf36dc5c628a3f6')
    version('3.0.x', git='https://github.com/TRIQS/dft_tools.git', branch='3.0.x')

    # TRIQS Dependencies
    depends_on('cmake', type='build')
    depends_on('mpi', type=('build', 'link'))
    depends_on('triqs', type=('build', 'link'))
    depends_on('python@3.7:', type=('build', 'link', 'run'))
    extends('python')
