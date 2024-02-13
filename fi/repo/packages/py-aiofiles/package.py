from spack.package import *
import spack.pkg.builtin.py_aiofiles


class PyAiofiles(spack.pkg.builtin.py_aiofiles.PyAiofiles):
    version("22.1.0", sha256="9107f1ca0b2a5553987a94a3c9959fe5b491fdf731389aa5b7b1bd0733e32de6")
