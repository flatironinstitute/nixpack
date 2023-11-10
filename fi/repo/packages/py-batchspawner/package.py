from spack.package import *
import spack.pkg.builtin.py_batchspawner as builtin

class PyBatchspawner(builtin.PyBatchspawner):
    git = "https://github.com/jupyterhub/batchspawner.git"

    version('main.2023-11-01', commit='35af66ade6735649d93c29df7bec641f0475795e')

    with when('@main.2023-11-01'):
        depends_on("python@3.6:3", type=("build", "run"))
        depends_on("py-jupyterhub@1.5.1:", type="run")
