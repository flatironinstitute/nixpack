from spack.package import *

class PyJupyterAppLauncher(PythonPackage):
    """Jupyter App Launcher"""

    homepage = "https://github.com/trungleduc/jupyter_app_launcher"
    pypi = "jupyter-app-launcher/jupyter_app_launcher-0.3.2.tar.gz"
    git = "https://github.com/trungleduc/jupyter_app_launcher"

    version("0.3.2", sha256="6740b50423e3e0e8dcdfda141a1c1c26ddfd2b900092155ee1b535ed7ac5ac7c")

    depends_on("py-setuptools", type="build")
    depends_on("py-jupyterlab", type=("build","run"))
    depends_on("py-jupyter-server", type="build")
    depends_on("py-hatchling", type="build")
    depends_on("py-hatch-nodejs-version", type="build")
    depends_on("py-pyyaml", type="run")
    depends_on("py-jsonschema", type="run")
    depends_on("npm", type="build")

    @run_after('install')
    def enable(self):
        jupyter = which("jupyter-server")
        jupyter("extension", "enable", "--user", "jupyter_app_launcher",
                extra_env={'JUPYTER_CONFIG_DIR': self.prefix.etc.jupyter})


