from spack import *
import spack.pkg.builtin.mathematica

class Mathematica(spack.pkg.builtin.mathematica.Mathematica):
    manual_download = False
    url = "file://{0}/Mathematica_12.0.0_LINUX.sh".format("/mnt/sw/pkg")

    version(
        "13.1.0",
        sha256="199c9462c971fcce1a148dcf8fd3acc37ff0efdfc9a7fe13de6444dbbee936e3",
        expand=False,
    )
