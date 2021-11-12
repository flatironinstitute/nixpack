from spack import *

class TriqsCthyb(CMakePackage):
    """TRIQS continuous-time hybridization-expansion solver"""

    homepage = "https://triqs.github.io/cthyb"
    url      = "https://github.com/TRIQS/cthyb/releases/download/3.0.0/cthyb-3.0.0.tar.gz"

    version('3.0.0', sha256='64970bfc73f5be819a87044411b4cc9e1f7996d122158c5c011046b7e1aec4e5')
    version('3.0.x', git='https://github.com/TRIQS/cthyb.git', branch='3.0.x')

    # TRIQS Dependencies
    depends_on('cmake', type='build')
    depends_on('mpi', type=('build', 'link'))
    depends_on('nfft', type=('build', 'link'))
    depends_on('triqs', type=('build', 'link'))
    depends_on('python@3.7:', type=('build', 'link', 'run'))
    variant('complex', default=False, description='Build with complex number support')
    extends('python')

    def cmake_args(self):
        args = super().cmake_args()
        if self.spec.satisfies('+complex'):
            args.append('-DHybridisation_is_complex=ON')
            args.append('-DLocal_hamiltonian_is_complex=ON')

        return args
