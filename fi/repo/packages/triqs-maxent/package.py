from spack import *

class TriqsMaxent(CMakePackage):
    """TRIQS: modular Maximum Entropy program to perform analytic continuation."""

    homepage = "https://triqs.github.io/maxent"
    url      = "https://github.com/TRIQS/maxent/releases/download/1.0.0/maxent-1.0.0.tar.gz"

    version('1.0.x', git='https://github.com/TRIQS/maxent.git', branch='1.0.x')

    # TRIQS Dependencies
    depends_on('cmake', type='build')
    depends_on('mpi', type=('build', 'link'))
    depends_on('triqs', type=('build', 'link'))
    depends_on('python@3.7:', type=('build', 'link', 'run'))
    extends('python')
