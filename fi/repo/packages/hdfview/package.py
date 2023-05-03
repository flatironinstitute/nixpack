
from spack.package import *
import spack.pkg.builtin.hdfview as builtin

class Hdfview(builtin.Hdfview):

    version("3.1.4",
            sha256="898fcd5227d4e7b697efde5e5a969405f96b72517f9dfbdbdce2991290fd56a0",
            url="https://support.hdfgroup.org/ftp/HDF5/releases/HDF-JAVA/hdfview-3.1.4/src/hdfview-3.1.4.tar.gz",
    )

    def setup_build_environment(self, env):
        env.set('ANT_HOME', self.spec['ant'].prefix)
