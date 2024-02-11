from spack.package import *

class PyWebsockify(PythonPackage):
    """websockify: WebSockets support for any application/server"""

    homepage = "https://github.com/novnc/websockify"
    git = "https://github.com/novnc/websockify.git"

    version("0.11.0", tag="v0.11.0", commit="e817fbdb1f06443fddd982c30434662277ab94f7")

    depends_on("py-setuptools", type="build")
    depends_on("py-numpy", type=("build", "run"))

    @run_after("install")
    def install_rebind(self):
        make('rebind.so')
        copy('rebind.so', self.prefix.lib)
