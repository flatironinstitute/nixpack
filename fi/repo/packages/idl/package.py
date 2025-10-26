import os
import stat

from spack_repo.builtin.build_systems.generic import Package
from spack.package import *

class Idl(Package):
    """IDL Software: Interactive Data Visulation.

    Note: IDL is a licensed software. You will also need an existing
    downloaded tarball of IDL in your current directory or in a
    spack mirror in order to install."""

    homepage = "https://www.harrisgeospatial.com/Software-Technology/IDL"
    manual_download = False
    url = "file://{0}/idl8.8.3-linux.tar.gz".format("/mnt/sw/pkg")

    version("8.8.3", sha256="5de8a95b1c552a9e3606848e426450268a79b785dbcd246aebfa3f1467f181c7")
    version("8.9", sha256="55c10a8ffc48d6f6cb219660dfc3f9b49010310cb9977eb0fd26f20e6e3ea655")
    version("9.0", sha256="8faf7ec8091ee77e6297f91a823e5c6216f2ab90909071955bec008c268b0f62")

    license_required = True

    @run_before("install")
    def pre_install(self):
        os.chmod("silent/idl_answer_file", stat.S_IRUSR | stat.S_IWUSR)
        # for version >= 9.0, revert default prefix:
        filter_file("/usr/local/nv5", "/usr/local/harris", "silent/idl_answer_file")

    def install(self, spec, prefix):
        # replace default install dir to self.prefix by editing answer file
        filter_file("/usr/local/harris", prefix, "silent/idl_answer_file")

        # execute install script
        install_script = Executable("./install.sh")
        install_script("-s", input="silent/idl_answer_file")

    def setup_run_environment(self, env):
        # set necessary environment variables
        env.prepend_path("EXELIS_DIR", self.prefix)
        env.prepend_path("IDL_DIR", self.prefix.idl)

        # add bin to path
        env.prepend_path("PATH", self.prefix.idl.bin)
