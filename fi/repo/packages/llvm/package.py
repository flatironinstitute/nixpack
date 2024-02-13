from spack import *
import spack.pkg.builtin.llvm

class Llvm(spack.pkg.builtin.llvm.Llvm):

    def cmake_args(self):
        args = [
            "-DCLANG_PYTHON_BINDINGS_VERSIONS:STRING=3",
            "-DLLDB_ENABLE_PYTHON:BOOL=ON",
            "-DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR:BOOL=OFF",
        ]
        args = list(super().cmake_args()) + args
        return args
