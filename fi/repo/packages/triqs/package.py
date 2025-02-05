from spack.package import *

class Triqs(CMakePackage):
    """TRIQS: a Toolbox for Research on Interacting Quantum Systems"""

    homepage = "https://triqs.github.io"
    url      = "https://github.com/TRIQS/triqs/archive/refs/tags/3.3.1.tar.gz"

    version('3.3.1', sha256='740efb57c9af39f4086115f8167a55833e84558261e0564c7179d8c17f911539')
    version('3.3.0', sha256='794bb02ed7e98498a93219831b270123ea0c893cc272ec9bb98217354b8f1b8d')
    version('3.2.1', sha256='f16103c6f7b68cd412cfb309f22f9ee4d379d794518432c0d514956a39ea05cb')
    version('3.2.0', sha256='b001ed1339ff6024f62b4e61fb8a955b044feac2d53b5a58575a3175e9bf6776')
    version('3.1.1', sha256='cf4f6064ea962fc088e0c2833bf7c4e52f4c827ea331bf3c57d1c9303649042b')
    version('3.1.0', sha256='f1f358ec73498bc7ac3ed9665829d8605908f7f7fc876a5c2a01efe37d368f0e')
    version('3.0.1', sha256='d555a4606c7ea2dde28aa8da056c6cc1ebbdd4e11cdb50b312b8c8f821a3edd2')

    variant('libclang', default=True, description='Build against libclang to enable c++2py support. ')

    # TRIQS Dependencies
    depends_on('cmake', type='build')
    depends_on('mpi', type=('build', 'link'))
    depends_on('blas', type=('build', 'link'))
    depends_on('lapack', type=('build', 'link'))
    depends_on('fftw@3:', type=('build', 'link'))
    depends_on('boost', type=('build', 'link'))
    depends_on('gmp', type=('build', 'link'))
    depends_on('hdf5', type=('build', 'link'))
    depends_on('llvm', type=('build', 'link'), when='+libclang')
    depends_on('python@3.7:', type=('build', 'link', 'run'))
    depends_on('py-scipy', type=('build', 'run'))
    depends_on('py-numpy', type=('build', 'run'))
    depends_on('py-h5py', type=('build', 'run'))
    depends_on('py-mpi4py', type=('build', 'run'))
    depends_on('py-matplotlib', type=('build', 'run'))
    depends_on('py-mako', type=('build', 'run'))
    depends_on('py-sphinx', type=('build', 'run'))

    extends('python')
