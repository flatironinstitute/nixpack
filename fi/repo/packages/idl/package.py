from spack import *
import spack.pkg.builtin.idl

class Idl(spack.pkg.builtin.idl.Idl):
    manual_download = False
    url = "file://{0}/idl8.8.3-linux.tar.gz".format("/mnt/sw/pkg")

    version("8.8.3", sha256="5de8a95b1c552a9e3606848e426450268a79b785dbcd246aebfa3f1467f181c7")
