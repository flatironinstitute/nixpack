from spack.package import *
import spack.pkg.builtin.py_maturin as builtin

class PyMaturin(builtin.PyMaturin):

    version("1.1.0", sha256="4650aeaa8debd004b55aae7afb75248cbd4d61cd7da2dcf4ead8b22b58cecae0")
    version("0.15.1", sha256="247bec13d82021972e5cb4eb38e7a7aea0e7a034beab60f0e0464ffe7423f24b")
    version("0.14.17", sha256="fb4e3311e8ce707843235fbe8748a05a3ae166c3efd6d2aa335b53dfc2bd3b88")
