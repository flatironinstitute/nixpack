from spack_repo.builtin.build_systems.cmake import CMakePackage
from spack.package import *

class TriqsHartreeFock(CMakePackage):
    """TRIQS: Hartree-Fock lattice and impurity solvers based on the TRIQS library"""

    homepage = "https://triqs.github.io/hartree_fock"
    url      = "https://github.com/TRIQS/hartree_fock/archive/refs/tags/3.3.0.tar.gz"

    version('3.3.0', sha256='4ed9d5637d5a82b113036a1e862f88ac79f9628fb07dc93f8299a5c9c9a471dc')

    # TRIQS Dependencies
    depends_on('cmake', type='build')
    depends_on('mpi', type=('build', 'link'))
    depends_on('triqs', type=('build', 'link'))
    depends_on('python@3.7:', type=('build', 'link', 'run'))
    extends('python')
