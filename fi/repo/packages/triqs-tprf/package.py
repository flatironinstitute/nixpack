from spack import *

class TriqsTprf(CMakePackage):
    """TRIQS: Two-Particle Response Function toolbox"""

    homepage = "https://triqs.github.io/tprf"
    url      = "https://github.com/TRIQS/tprf/releases/download/3.0.0/tprf-3.0.0.tar.gz"

    version('3.0.0', sha256='8e20620145bb8cbcc187f4637884457c0cacaed79ba6e1709a951046ee5ffc4b')
    version('3.0.x', git='https://github.com/TRIQS/tprf.git', branch='3.0.x')

    # TRIQS Dependencies
    depends_on('cmake', type='build')
    depends_on('mpi', type=('build', 'link'))
    depends_on('triqs', type=('build', 'link'))
    depends_on('python@3.7:', type=('build', 'link', 'run'))
    extends('python')
