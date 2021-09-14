from spack import *

class Stkfmm(CMakePackage):
    """A C++ library implements the Kernel Aggregated Fast Multipole Method based on the library PVFMM."""

    homepage = "https://github.com/flatironinstitute/stkfmm"
    url      = "https://github.com/flatironinstitute/stkfmm/archive/refs/tags/v1.0.0.tar.gz"

    maintainers = ['blackwer', 'wenyan4work']
    version('1.0.0', sha256='029de6f1872d5d72b9810f9f2319b665dfe05dd73fcac60820c9091338c54f3f')
    depends_on('blas', type=('build', 'run'))
    depends_on('mpi', type=('build', 'run'))
    depends_on('eigen', type=('build'))
    depends_on('fftw-api@3', type=('build', 'run'))
    depends_on('pvfmm+extended_bc', type=('build', 'run'))

    variant('python', True)

    def cmake_args(self):
        cxx_flags = '-g'
        options = []
        if '+python' in self.spec:
            options.append(CMakePackage.define('PyInterface', True))
        options.append(CMakePackage.define('CMAKE_CXX_FLAGS', cxx_flags))

        return options
