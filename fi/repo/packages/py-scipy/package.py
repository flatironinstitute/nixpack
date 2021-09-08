from spack import *
import spack.pkg.builtin.py_scipy

class PyScipy(spack.pkg.builtin.py_scipy.PyScipy):
    def setup_build_environment(self, env):
        super().setup_build_environment(env)
        env.set('NPY_NUM_BUILD_JOBS', make_jobs)
