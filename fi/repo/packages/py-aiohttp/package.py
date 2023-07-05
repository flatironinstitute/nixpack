from spack.package import *
import spack.pkg.builtin.py_aiohttp as builtin

class PyAiohttp(builtin.PyAiohttp):
    version("3.8.4", sha256="bf2e1a9162c1e441bf805a1fd166e249d574ca04e03b34f97e2928769e91ab5c")

    depends_on("py-charset-normalizer@2.0:3", type=("build", "run"), when="@3.8.4:")
