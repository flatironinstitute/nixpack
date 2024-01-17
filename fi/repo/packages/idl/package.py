import os
import stat

from spack import *
import spack.pkg.builtin.idl

class Idl(spack.pkg.builtin.idl.Idl):
    manual_download = False
    url = "file://{0}/idl8.8.3-linux.tar.gz".format("/mnt/sw/pkg")

    version("8.8.3", sha256="5de8a95b1c552a9e3606848e426450268a79b785dbcd246aebfa3f1467f181c7")
    version("8.9", sha256="55c10a8ffc48d6f6cb219660dfc3f9b49010310cb9977eb0fd26f20e6e3ea655")
    version("9.0", sha256="8faf7ec8091ee77e6297f91a823e5c6216f2ab90909071955bec008c268b0f62")

    @run_before("install")
    def pre_install(self):
        os.chmod("silent/idl_answer_file", stat.S_IRUSR | stat.S_IWUSR)
        # for version >= 9.0, revert default prefix:
        filter_file("/usr/local/nv5", "/usr/local/harris", "silent/idl_answer_file")
