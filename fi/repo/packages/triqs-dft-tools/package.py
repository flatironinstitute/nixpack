from spack import *

class TriqsDftTools(CMakePackage):
    """TRIQS: continuous-time hybridization-expansion solver"""

    homepage = "https://triqs.github.io/dft_tools"
    url      = "https://github.com/TRIQS/dft_tools/releases/download/3.0.0/dft_tools-3.0.0.tar.gz"

    version('3.2.0', sha256='77d89bc5c9a36636a720b6cae78967cd6dd83d0018c854a68bef91219a456307')
    version('3.1.0', sha256='57b7d0fe5a96c5a42bb684c60ca8e136a33e1385bf6cd7e9d1371fa507dc2ec4')
    version('3.0.0', sha256='646d1d2dca5cf6ad90e18d0706124f701aa94ec39c5236d8fcf36dc5c628a3f6')

    # TRIQS Dependencies
    depends_on('cmake', type='build')
    depends_on('mpi', type=('build', 'link'))
    depends_on('triqs', type=('build', 'link'))
    depends_on('python@3.7:', type=('build', 'link', 'run'))
    extends('python')
