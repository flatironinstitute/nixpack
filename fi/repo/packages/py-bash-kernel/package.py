from spack import *
import spack.pkg.builtin.py_bash_kernel

class PyBashKernel(spack.pkg.builtin.py_bash_kernel.PyBashKernel):
    depends_on('py-ipykernel', type=('build', 'run'))
