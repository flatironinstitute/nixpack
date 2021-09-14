from spack import *

class Stkfmm(CMakePackage):
    """PVFMM is a library for solving certain types of elliptic partial differential equations."""

    homepage = "https://github.com/flatironinstitute/stkfmm"
    url      = "https://github.com/flatironinstitute/stkfmm/archive/refs/tags/v1.0.0.tar.gz"

    maintainers = ['blackwer', 'wenyan4work']
    version('1.0.0', sha256='029de6f1872d5d72b9810f9f2319b665dfe05dd73fcac60820c9091338c54f3f')
    depends_on('blas')
    depends_on('mpi')
    depends_on('eigen')
    depends_on('fftw-api')
    depends_on('pvfmm+extended_bc')

    variant('python', True)

    def cmake_args(self):
        cxx_flags = '-g'
        options = []
        if '+python' in self.spec:
            options.append(CMakePackage.define('PyInterface', True))
        options.append(CMakePackage.define('CMAKE_CXX_FLAGS', cxx_flags))

        return options
