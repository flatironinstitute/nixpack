from spack import *
import spack.pkg.builtin.py_yt

class PyYt(spack.pkg.builtin.py_yt.PyYt):
    version('4.0.1', sha256='da9f9b03a3fe521396006a0fdc0e10c1eba09113d9ac0a40455a299694230104')
    depends_on("py-unyt", type=('build', 'run'), when="@4:")
    depends_on("py-cmyt", type=('build', 'run'), when="@4:")
