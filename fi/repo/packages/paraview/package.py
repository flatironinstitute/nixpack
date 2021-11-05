from spack import *
import spack.pkg.builtin.paraview
import os

class Paraview(spack.pkg.builtin.paraview.Paraview):
    def cmake_args(self):
        return [x.upper() if x.startswith('-DPARAVIEW_BUILD_EDITION') else x
                for x in super().cmake_args()]

    @run_after('install')
    def install_wrapper(self):
        paraview_src = os.path.join(self.prefix.bin, 'paraview')
        paraview_dst = os.path.join(self.prefix.bin, 'paraview-real')
        move(paraview_src, paraview_dst)

        wrapper_src = os.path.join(self.package_dir, 'paraview_wrapper.sh')
        copy(wrapper_src, paraview_src)
