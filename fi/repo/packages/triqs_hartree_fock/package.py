from spack_repo.builtin.build_systems.cmake import CMakePackage
from spack.package import *

class TriqsHartreeFock(CMakePackage):
    """TRIQS: Hartree-Fock lattice and impurity solvers based on the TRIQS library"""

    homepage = "https://triqs.github.io/hartree_fock"
    url      = "https://github.com/TRIQS/hartree_fock/archive/refs/tags/3.3.0.tar.gz"

    version('4.0.0', sha256='27c9ed1f2ee745058d8ed05626ef0994a35c5f45d9319f0cf2c93ce226c719e2')

    # TRIQS Dependencies
    depends_on("c", type="build")
    depends_on("cxx", type="build")
    depends_on("fortran", type="build")
    depends_on('cmake', type='build')
    depends_on('mpi', type=('build', 'link'))
    depends_on('triqs', type=('build', 'link'))
    depends_on('python@3.7:', type=('build', 'link', 'run'))
    extends('python')
