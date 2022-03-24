import os
import spack.pkg.builtin.py_ipyparallel as builtin

class PyIpyparallel(builtin.PyIpyparallel):
    version('8.2.0', sha256='0fd9f64a5120980a89b64299806c12bb8df8ceea155e5200b705301eb2401e19')
    version('8.1.0', sha256='63f7e136e88f890e9802522fa5475dd81e7614ba06a8cfe4f80cc3056fdb7d73')
    depends_on('npm', type='build')
