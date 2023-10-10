from spack import *

class TriqsCthyb(CMakePackage):
    """TRIQS continuous-time hybridization-expansion solver"""

    homepage = "https://triqs.github.io/cthyb"
    url      = "https://github.com/TRIQS/cthyb/releases/download/3.0.0/cthyb-3.0.0.tar.gz"

    version('3.2.1', sha256='6f4cd36efcd19b0f1efbed2c9aa6d2640ef84f8fcf7b97675af8d54cdc327c9f')
    version('3.1.0', sha256='8d6d2c4d5b3928d062b72fad4ea9df9aae198e39dd9c1fd3cc5dc34a5019acc0')
    version('3.0.0', sha256='64970bfc73f5be819a87044411b4cc9e1f7996d122158c5c011046b7e1aec4e5')

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
