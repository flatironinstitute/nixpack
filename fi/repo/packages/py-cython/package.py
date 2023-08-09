from spack.package import *
import spack.pkg.builtin.py_cython as builtin

class PyCython(builtin.PyCython):

    version("3.0.0b2", sha256="6c4280656579e924c119447247664bb22fafedc7decca593a8ea20bdd57d6755")
