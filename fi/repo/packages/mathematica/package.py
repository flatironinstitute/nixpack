from spack import *
import spack.pkg.builtin.mathematica

class Mathematica(spack.pkg.builtin.mathematica.Mathematica):
    manual_download = False
    url = "file://{0}/Mathematica_12.0.0_LINUX.sh".format("/mnt/sw/pkg")

    version(
        "13.2.1",
        sha256="180da4fa3bc4e264c9b086cc1dc7b9739d7a87f8251cb9d776d8447e7366934c",
        expand=False,
    )
    version(
        "13.1.0",
        sha256="199c9462c971fcce1a148dcf8fd3acc37ff0efdfc9a7fe13de6444dbbee936e3",
        expand=False,
    )
    version(
        "12.3.0",
        sha256="045df045f6e796ded59f64eb2e0f1949ac88dcba1d5b6e05fb53ea0a4aed7215",
        expand=False,
    )
