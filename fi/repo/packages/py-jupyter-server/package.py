from spack import *
import spack.pkg.builtin.py_jupyter_server

class PyJupyterServer(spack.pkg.builtin.py_jupyter_server.PyJupyterServer):
    depends_on('npm', type='build')
