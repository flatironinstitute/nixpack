from spack_repo.builtin.build_systems.cmake import CMakePackage
from spack.package import *

class Pvfmm(CMakePackage):
    """PVFMM is a library for solving certain types of elliptic partial differential equations."""

    homepage = "https://pvfmm.org"
    git      = "https://github.com/dmalhotra/pvfmm.git"

    maintainers = ['blackwer', 'dmalhotra']

    version('1.3.0', commit='d820725558838879ff916cb3c328260b45b11078', submodules=True)
    depends_on('blas', type=('build', 'link'))
    depends_on('mpi', type=('build', 'link'))
    depends_on('fftw-api@3', type=('build', 'link'))

    variant('extended_bc', True)

    def cmake_args(self):
        cxx_flags = '-g'
        options = []
        if '+extended_bc' in self.spec:
            cxx_flags += ' -DPVFMM_EXTENDED_BC'

        return [self.define('CMAKE_CXX_FLAGS', cxx_flags)]
