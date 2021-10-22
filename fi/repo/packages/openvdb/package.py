import spack.pkg.builtin.openvdb as builtin

class Openvdb(builtin.Openvdb):
    def cmake_args(self):
        args = super().cmake_args()
        args.append(self.define('USE_CCACHE', False))
        return args

    @run_before("install")
    def fix_module_vars(self):
        if "+python" in self.spec:
            builtin.site_packages_dir = site_packages_dir
