from spack import *

class Stkfmm(CMakePackage):
    """A C++ library implements the Kernel Aggregated Fast Multipole Method based on the library PVFMM."""

    homepage = "https://github.com/flatironinstitute/stkfmm"
    git      = "https://github.com/flatironinstitute/stkfmm.git"

    maintainers = ['blackwer', 'wenyan4work']
    version('1.1.0', commit='56bfce38397b19a245cca2a1a8c47a221aa2da40')
    depends_on('blas', type=('build', 'link'))
    depends_on('mpi', type=('build', 'link'))
    depends_on('eigen', type=('build'))
    depends_on('fftw-api@3', type=('build', 'link'))
    depends_on('pvfmm+extended_bc', type=('build', 'link'))

    variant('python', True)

    def cmake_args(self):
        cxx_flags = '-g'
        options = []
        if '+python' in self.spec:
            options.append(self.define('PyInterface', True))
        options.append(self.define('CMAKE_CXX_FLAGS', cxx_flags))

        return options
