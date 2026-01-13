from spack_repo.builtin.build_systems.cmake import CMakePackage
from spack.package import *

class TriqsCtseg(CMakePackage):
    """A segment picture impurity solver with spin-spin interactions. """

    homepage = "https://triqs.github.io/ctseg"
    url      = "https://github.com/TRIQS/ctseg/archive/refs/tags/3.3.0.tar.gz"

    version('3.3.0', sha256='2fc8c358e339b22d40c7d8b8b60f2a6f61bce786045f3fe0831b86447e2e9c8f')

    # TRIQS Dependencies
    depends_on("c", type="build")
    depends_on("cxx", type="build")
    depends_on('cmake', type='build')
    depends_on('mpi', type=('build', 'link'))
    depends_on('nfft', type=('build', 'link'))
    depends_on('triqs', type=('build', 'link'))
    depends_on('python@3.7:', type=('build', 'link', 'run'))
    variant('complex', default=False, description='Build with complex number support')
    extends('python')
