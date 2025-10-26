from spack_repo.builtin.build_systems.python import PythonPackage
from spack.package import *


class PyHdf5plugin(PythonPackage):
    '''hdf5plugin provides HDF5 compression filters (namely: Blosc, Blosc2,
    BitShuffle, BZip2, FciDecomp, LZ4, SZ, SZ3, Zfp, ZStd) and makes them
    usable from h5py.
    '''
    
    # http://www.silx.org/doc/hdf5plugin/latest/install.html

    pypi = 'hdf5plugin/hdf5plugin-4.1.1.tar.gz'

    version("4.1.1", sha256="96a989679f1f38251e0dcae363180d382ba402f6c89aab73ca351a391ac23b36")

    # Don't link against compression libs in the spec. hdf5plugin is doing static inclusions.
    depends_on('hdf5')
    depends_on('py-setuptools', type='build')
    depends_on('py-py-cpuinfo@8.0.0', type='build')
    depends_on('py-wheel', type='build')

    def setup_build_environment(self, env):
        env.set('HDF5PLUGIN_HDF5_DIR', self.spec['hdf5'].prefix)
        env.set('HDF5PLUGIN_OPENMP', 'True')
        env.set('HDF5PLUGIN_NATIVE', 'False')
        env.set('HDF5PLUGIN_SSE2', 'True' if 'sse2' in self.spec.target else 'False')
        env.set('HDF5PLUGIN_AVX2', 'True' if 'avx2' in self.spec.target else 'False')
        env.set('HDF5PLUGIN_AVX512', 'True' if 'avx512' in self.spec.target else 'False')
        env.set('HDF5PLUGIN_BMI2', 'True' if 'bmi2' in self.spec.target else 'False')
        env.set('HDF5PLUGIN_CPP11', 'True')
        env.set('HDF5PLUGIN_CPP14', 'True')
        # env.set('HDF5PLUGIN_INTEL_IPP_DIR', )
