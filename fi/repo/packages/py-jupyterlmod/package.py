from spack.package import *

class PyJupyterlmod(PythonPackage):
    """Jupyter plugin for TACC Lmod"""

    homepage = "https://github.com/cmd-ntrf/jupyter-lmod"
    pypi = "jupyterlmod/jupyterlmod-4.0.3.tar.gz"

    version("4.0.3", sha256="e39dfddc841c488cf82fe3c9fa40d5a22766f29772220e30a9c95658515733d8")

    depends_on("py-setuptools", type="build")
    depends_on("py-notebook", type=("build","run"))
    depends_on("py-jupyterlab@3", type=("build","run"))
    depends_on("py-jupyter-server-proxy", type=("build","run"))
    depends_on("lmod", type=("build","run"))
    depends_on("py-hatch-jupyter-builder", type="build")
    depends_on("py-hatch-nodejs-version", type="build")
    depends_on("py-hatchling", type="build")
    depends_on("npm", type="build")
