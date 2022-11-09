from spack import *

class Pvfmm(CMakePackage):
    """PVFMM is a library for solving certain types of elliptic partial differential equations."""

    homepage = "https://pvfmm.org"
    url      = "https://github.com/dmalhotra/pvfmm/archive/refs/tags/v1.2.1.tar.gz"

    maintainers = ['blackwer', 'dmalhotra']

    version('1.2.1', sha256='726ffb32c33bd38a6f87ef55affbe7ce538c306c59ce78510cc09b0de2f641d4')
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
