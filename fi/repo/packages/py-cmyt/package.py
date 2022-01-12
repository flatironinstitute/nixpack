from spack import *

class PyCmyt(PythonPackage):
    homepage = "https://github.com/yt-project/cmyt"
    pypi     = "cmyt/cmyt-1.0.4.tar.gz"

    version('1.0.4', sha256='ae5157d37e733ae55df12bad1e8aedb3eb2f3b45e829e25c83df023dcefd5926')

    depends_on("py-setuptools", type=('build'))
    depends_on("py-colorspacious@1.1.2:", type=('build', 'run'))
    depends_on("py-matplotlib@2.1.0:", type=('build', 'run'))
    depends_on("py-more-itertools@8.4:", type=('build', 'run'))
    depends_on("py-numpy@1.13.3:", type=('build', 'run'))
    depends_on("py-typing-extensions@3.10.0.2:", type=('build', 'run'))
