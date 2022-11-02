from spack import *
import spack.pkg.builtin.mathematica

class Mathematica(spack.pkg.builtin.mathematica.Mathematica):
    manual_download = False
    url = "file://{0}/Mathematica_12.0.0_LINUX.sh".format("/mnt/sw/pkg")
