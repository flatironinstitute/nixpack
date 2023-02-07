from spack.package import *
import spack.pkg.builtin.py_extension_helpers as builtin

class PyExtensionHelpers(builtin.PyExtensionHelpers):
    version("1.0.0", sha256="ca1bfac67c79cf4a7a0c09286ce2a24eec31bf17715818d0726318dd0e5050e6")

    patch('_setup_helpers.py.patch')
