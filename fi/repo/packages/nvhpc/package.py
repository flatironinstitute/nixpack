import spack.pkg.builtin.nvhpc as builtin

class Nvhpc(builtin.Nvhpc):
    variant("stdpar", default='none', values=['none']+list(spack.build_systems.cuda.CudaPackage.cuda_arch_values))

    def setup_run_environment(self, env):
        super().setup_run_environment(env)
        # mpi and other things need libatomic!
        for p in self.compiler.implicit_rpaths():
            env.append_path('LD_LIBRARY_PATH', p)

    def install(self, spec, prefix):
        super().install(spec, prefix)
        cbin = "%s/%s/%s/compilers/bin" % \
                (prefix, 'Linux_%s' % spec.target.family, self.version)
        makelocalrc = Executable(cbin + "/makelocalrc")
        stdpar = spec.variants['stdpar'].value
        makelocalrc('-x', cbin,
                '-gcc', self.compiler.cc,
                '-gpp', self.compiler.cxx,
                '-g77', self.compiler.f77,
                '-stdpar', '' if stdpar == 'none' else stdpar)
