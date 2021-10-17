import sys
import spack.pkg.builtin.llvm as builtin

class Llvm(builtin.Llvm):
    variant("pythonbind", default=False, description="Install generic python bindings")

    @run_before("install")
    def fix_module_vars(self):
        if "+python" in self.spec:
            builtin.site_packages_dir = site_packages_dir

    def cmake_args(self):
        cmake_args = super().cmake_args()
        if '+pythonbind' in self.spec:
            cmake_args.append("-DCLANG_PYTHON_BINDINGS_VERSIONS=3")
        return cmake_args
