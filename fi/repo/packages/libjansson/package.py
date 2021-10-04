from spack import *

class Libjansson(CMakePackage):
    """libjansson"""

    homepage = "https://digip.org/jansson/"
    url      = "http://digip.org/jansson/releases/jansson-2.13.tar.gz"

    version('2.13.1', sha256='f4f377da17b10201a60c1108613e78ee15df6b12016b116b6de42209f47a474f')
