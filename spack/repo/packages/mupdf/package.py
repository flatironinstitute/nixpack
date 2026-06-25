from spack_repo.builtin.build_systems.makefile import MakefilePackage
from spack.package import *


class Mupdf(MakefilePackage):
    """ MuPDF is a lightweight PDF, XPS, and E-book viewer. """

    homepage = "https://www.example.com"
    url      = "https://casper.mupdf.com/downloads/archive/mupdf-1.27.2-source.tar.gz"

    version('1.27.2',     sha256='553867b135303dc4c25ab67c5f234d8e900a0e36e66e8484d99adc05fe1e8737')

    depends_on("c", type="build")
    depends_on("cxx", type="build")
    depends_on('openssl')
    depends_on('curl')
    depends_on('libxext')
    depends_on('libxau')

    def edit(self, spec, prefix):
        self.install_targets.append('prefix={}'.format(prefix))
