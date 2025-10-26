from spack_repo.builtin.build_systems.makefile import MakefilePackage
from spack.package import *


class Mupdf(MakefilePackage):
    """ MuPDF is a lightweight PDF, XPS, and E-book viewer. """

    homepage = "https://www.example.com"
    url      = "https://mupdf.com/downloads/archive/mupdf-1.18.0-source.tar.xz"

    version('1.18.0',     sha256='592d4f6c0fba41bb954eb1a41616661b62b134d5b383e33bd45a081af5d4a59a')
    version('1.17.0',     sha256='c935fb2593d9a28d9b56b59dad6e3b0716a6790f8a257a68fa7dcb4430bc6086')
    version('1.16.1',     sha256='6fe78184bd5208f9595e4d7f92bc8df50af30fbe8e2c1298b581c84945f2f5da')
    version('1.16.0',     sha256='d28906cea4f602ced98f0b08d04138a9a4ac2e5462effa8c45f86c0816ab1da4')
    version('1.15.0',     sha256='565036cf7f140139c3033f0934b72e1885ac7e881994b7919e15d7bee3f8ac4e')
    version('1.14.0',     sha256='603e69a96b04cdf9b19a3e41bd7b20c63b39abdcfba81a7460fcdcc205f856df')
    version('1.13.0',     sha256='746698e0d5cd113bdcb8f65d096772029edea8cf20704f0d15c96cb5449a4904')
    version('1.12.0',     sha256='577b3820c6b23d319be91e0e06080263598aa0662d9a7c50af500eb6f003322d')

    depends_on('openssl')
    depends_on('curl')
    depends_on('libxext')
    depends_on('libxau')

    def edit(self, spec, prefix):
        env['XCFLAGS'] = "-std=c99"
        self.install_targets.append('prefix={}'.format(prefix))
