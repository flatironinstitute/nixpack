import spack.pkg.builtin.nvhpc as builtin

class Nvhpc(builtin.Nvhpc):
    def setup_run_environment(self, env):
        super().setup_run_environment(env)
        # mpi and other things need libatomic!
        for p in self.compiler.implicit_rpaths():
            env.append_path('LD_LIBRARY_PATH', p)
