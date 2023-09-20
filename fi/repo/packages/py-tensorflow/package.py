from spack import *
import spack.pkg.builtin.py_tensorflow as builtin

class PyTensorflow(builtin.PyTensorflow):

    @run_after("configure")
    def post_configure_fixes(self):
        super().post_configure_fixes()

        if self.spec.satisfies("@2.7:"):
            filter_file(
                r"(^\s*)'platform_system",
                r"\1#'platform_system",
                "tensorflow/tools/pip_package/setup.py",
            )
