from spack import *
import spack.pkg.builtin.intel_oneapi_mkl

class IntelOneapiMkl(spack.pkg.builtin.intel_oneapi_mkl.IntelOneapiMkl):
    def setup_run_environment(self, env):
        super().setup_run_environment(env)
        env.append_path('CMAKE_PREFIX_PATH', self.component_path)

    def setup_dependent_build_environment(self, env, dependent_spec):
        self.setup_run_environment(env)

        include_path = join_path(self.component_path, 'include')
        lib_path = join_path(self.component_path, 'lib', 'intel64')
        env.append_path('CMAKE_LIBRARY_PATH', lib_path)
        env.append_path('CMAKE_INCLUDE_PATH', include_path)
        env.append_path('SPACK_COMPILER_EXTRA_RPATHS', lib_path)

