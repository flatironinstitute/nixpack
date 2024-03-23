from spack.package import *

class PyJupyterRemoteDesktopProxy(PythonPackage):
    """Jupyter Remote Desktop Proxy"""

    homepage = "https://github.com/jupyterhub/jupyter-remote-desktop-proxy"
    pypi = "jupyter-remote-desktop-proxy/jupyter-remote-desktop-proxy-1.2.1.tar.gz"
    git = "https://github.com/flatironinstitute/jupyter-remote-desktop-proxy"

    version("main", branch="main", commit="f2a80f279c8e275caa8441ab0df5ad3d28d37f9a")
    version("1.2.1", sha256="8adf71303e653360653c7dc5b9c1a836a239ab3fb2884d3259846046f6b82bda")

    depends_on("py-setuptools", type="build")
    depends_on("py-jupyter-server", type="build")
    depends_on("py-jupyter-server-proxy", type="run")
    depends_on("py-websockify", type="run")
    depends_on("npm", type="build")

    @run_after('install')
    def enable(self):
        jupyter = which("jupyter-server")
        jupyter("extension", "enable", "--user", "jupyter_remote_desktop_proxy",
                extra_env={'JUPYTER_CONFIG_DIR': self.prefix.etc.jupyter})
