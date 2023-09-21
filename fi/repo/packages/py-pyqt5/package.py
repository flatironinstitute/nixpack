from spack.package import *
import spack.pkg.builtin.py_pyqt5 as builtin

class PyPyqt5(builtin.PyPyqt5):

    def configure_args(self):
        # Would prefer to use --designer-plugindir, but it doesn't seem to work.
        # This may be because of SIPPackage using `make` instead of `sip-install`.
        return super().configure_args() + [
            '--no-designer-plugin',
            '--no-qml-plugin',
        ]
