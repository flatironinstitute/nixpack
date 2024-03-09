from spack import *
import spack.pkg.builtin.py_jupyter_server_proxy

class PyJupyterServerProxy(spack.pkg.builtin.py_jupyter_server_proxy.PyJupyterServerProxy):
    # backports of PRs
    git = "https://github.com/dylex/jupyter-server-proxy"
    version("4.1", branch="4.1", commit="a23cdc5d7ddce365be8e02ebe17120a43684847b")
    version("4.0", branch="4.0", commit="2ce3c2d3663da19c9b6fe26da35f454d4bdc8667")
