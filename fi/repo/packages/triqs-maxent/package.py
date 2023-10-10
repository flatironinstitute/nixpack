from spack import *

class TriqsMaxent(CMakePackage):
    """TRIQS: modular Maximum Entropy program to perform analytic continuation."""

    homepage = "https://triqs.github.io/maxent"
    url      = "https://github.com/TRIQS/maxent/releases/download/1.0.0/maxent-1.0.0.tar.gz"

    version('1.2.0', sha256='41be8c4233df47c7c4454bce9b611d0dc8fb117778a5c4f7352ebf6bd7b9ac77')
    version('1.1.1', sha256='b0e00bcd5e8b143faf23d47225c53b8ceec36537ce4a97fe725874e7e9214289')
    version('1.1.0', sha256='87523adabdfe0c6d0a1fd84bdc1b4bceed64361adde922809d85e19c155e4c68')
    version('1.0.0', sha256='798383792902b5085ec3da01ddd2866fa337037bfdffe1df42475624fe0cb1a8')

    # TRIQS Dependencies
    depends_on('cmake', type='build')
    depends_on('mpi', type=('build', 'link'))
    depends_on('triqs', type=('build', 'link'))
    depends_on('python@3.7:', type=('build', 'link', 'run'))
    extends('python')
