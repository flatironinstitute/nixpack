from spack_repo.builtin.build_systems.cmake import CMakePackage
from spack.package import *

class TriqsTprf(CMakePackage):
    """TRIQS: Two-Particle Response Function toolbox"""

    homepage = "https://triqs.github.io/tprf"
    url      = "https://github.com/TRIQS/tprf/archive/refs/tags/3.3.1.tar.gz"

    version('3.3.1', sha256='4a39648629888ec07c1a5c333ae5aa85ac04a46a7ec3b5d5d588cfe5246b7572')
    version('3.3.0', sha256='e703b490873293efa2835147c73b19b90860fe2e2d8b1ec9da79c8b602512b10')
    version('3.2.1', sha256='f1d4dd5986af4b37dc65f3af2a0be507455f0b4a74ea7d4de892739ccd86158c')
    version('3.1.1', sha256='63d4de9cfc3daf0d74db45cfa7445b817fd22a38a8485db3ce9a81febe263b50')
    version('3.1.0', sha256='75f6e79d891342951652353ea4d9914074d9947c67cad60844ebaa3f82bd17b5')
    version('3.0.0', sha256='8e20620145bb8cbcc187f4637884457c0cacaed79ba6e1709a951046ee5ffc4b')

    # TRIQS Dependencies
    depends_on("c", type="build")
    depends_on("cxx", type="build")
    depends_on('cmake', type='build')
    depends_on('mpi', type=('build', 'link'))
    depends_on('triqs', type=('build', 'link'))
    depends_on('python@3.7:', type=('build', 'link', 'run'))
    extends('python')
