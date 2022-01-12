from spack import *

class PyUnyt(PythonPackage):
    homepage = "https://github.com/yt-project/unyt"
    pypi     = "unyt/unyt-2.8.0.tar.gz"

    version('2.8.0', sha256='6a17f849af0ec376fccb111c26b767022189d157d416f0fe5078f31b6b01a22e')

    depends_on("py-setuptools", type=('build'))
    depends_on("py-numpy@1.13.0:", type=('build', 'run'))
    depends_on("py-sympy@1.2:", type=('build', 'run'))
