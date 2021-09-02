import sys
# somehow the package doesn't resolve correctly in some environments...
try:
    builtin = sys.modules['spack.pkg.builtin.llvm']
except KeyError:
    import spack.pkg.builtin.llvm as builtin

class Llvm(builtin.Llvm):
    # we had removed family = 'compiler' before but I don't think it's necessary? (see lmod tempalte change)

    def setup_run_environment(self, env):
        pass

    @run_before("install")
    def fix_module_vars(self):
        if "+python" in self.spec:
            builtin.site_packages_dir = site_packages_dir
