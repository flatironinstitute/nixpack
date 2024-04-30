from spack import *
import spack.pkg.builtin.py_jupyter_server_proxy

class PyJupyterServerProxy(spack.pkg.builtin.py_jupyter_server_proxy.PyJupyterServerProxy):
    # backports of PRs
    git = "https://github.com/dylex/jupyter-server-proxy"
    version("4.1", branch="4.1", commit="2127704c575c109f39a5a53b9be6a9cd261fed92")
