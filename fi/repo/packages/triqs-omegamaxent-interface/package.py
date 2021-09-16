from spack import *

class TriqsOmegamaxentInterface(CMakePackage):
    """TRIQS: python interface to the maximum entropy analytic continuation program OmegaMaxEnt"""

    homepage = "https://triqs.github.io/omegamaent_interface"
    url      = "https://github.com/TRIQS/omegamaxent_interface/releases/download/3.0.0/omegamaxent_interface-3.0.0.tar.gz"

    version('3.0.x', git='https://github.com/TRIQS/omegamaxent_interface.git', branch='3.0.x')

    # TRIQS Dependencies
    depends_on('cmake', type='build')
    depends_on('mpi', type=('build', 'link'))
    depends_on('triqs', type=('build', 'link'))
    depends_on('python@3.7:', type=('build', 'link', 'run'))
    extends('python')
