from spack.package import *
import spack.pkg.builtin.ncbi_vdb as builtin


class NcbiVdb(builtin.NcbiVdb):
    homepage = "https://github.com/ncbi/ncbi-vdb"
    git = "https://github.com/ncbi/ncbi-vdb.git"

    version("3.0.2", tag="3.0.2")
