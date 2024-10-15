from spack.package import *
import spack.pkg.builtin.py_extension_helpers as builtin

class PyExtensionHelpers(builtin.PyExtensionHelpers):
    patch('_setup_helpers.py.patch')
