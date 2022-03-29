from spack import *

class TriqsOmegamaxentInterface(CMakePackage):
    """TRIQS: python interface to the maximum entropy analytic continuation program OmegaMaxEnt"""

    homepage = "https://triqs.github.io/omegamaent_interface"
    url      = "https://github.com/TRIQS/omegamaxent_interface/archive/refs/tags/3.0.0.tar.gz"

    version('3.1.0', sha256='1a77080314a0e448379180337b572af2fb20fcb6d50312588d4532d0938f81c8')
    version('3.0.0', sha256='fef80d36bea614820bdb2fa650ff545d6099cd4c478276a96d0ff30ed8844338')

    # TRIQS Dependencies
    depends_on('cmake', type='build')
    depends_on('mpi', type=('build', 'link'))
    depends_on('triqs', type=('build', 'link'))
    depends_on('python@3.7:', type=('build', 'link', 'run'))
    depends_on('blas', type=('build', 'link', 'run'))
    depends_on('fftw', type=('build', 'link', 'run'))
    depends_on('gsl', type=('build', 'link', 'run'))
    extends('python')
