from spack import *

class TriqsHubbardi(CMakePackage):
    """TRIQS: Hubbard I solver"""

    homepage = "https://triqs.github.io/hubbardI"
    url      = "https://github.com/TRIQS/hubbardI/archive/refs/tags/3.3.0.tar.gz"

    version('3.3.0', sha256='374fb0d7c5a52f9bda3763cb6910a9bdeb8f2e3d1494dfe1024f3e0be098edf6')

    # TRIQS Dependencies
    depends_on('cmake', type='build')
    depends_on('mpi', type=('build', 'link'))
    depends_on('triqs', type=('build', 'link'))
    depends_on('python@3.7:', type=('build', 'link', 'run'))
    extends('python')
