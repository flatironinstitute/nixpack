from spack import *
import spack.pkg.builtin.py_pycuda

class PyPycuda(PythonPackage):
    """PyCUDA gives you easy, Pythonic access to Nvidia's CUDA parallel
    computation API
    """

    homepage = "https://mathema.tician.de/software/pycuda/"
    pypi = "pycuda/pycuda-2019.1.2.tar.gz"
    version('2021.1', sha256='ab87312d0fc349d9c17294a087bb9615cffcf966ad7b115f5b051008a48dd6ed')
    version('2020.1', sha256='effa3b99b55af67f3afba9b0d1b64b4a0add4dd6a33bdd6786df1aa4cc8761a5')

    depends_on('py-setuptools', type='build')
    depends_on('cuda')
    depends_on('python@3.6:3.999', type=('build', 'run'))
    depends_on('py-numpy@1.6:', type=('build', 'run'))
    depends_on('py-pytools@2011.2:', type=('build', 'run'))
    depends_on('py-six', type='run')
    depends_on('py-decorator@3.2.0:', type=('build', 'run'))
    depends_on('py-appdirs@1.4.0:', type=('build', 'run'))
    depends_on('py-mako', type=('build', 'run'))
