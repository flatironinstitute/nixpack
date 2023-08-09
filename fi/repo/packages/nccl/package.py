from spack.package import *
import spack.pkg.builtin.nccl as builtin

class Nccl(builtin.Nccl):
    version("2.18.1-1", sha256="0e4ede5cf8df009bff5aeb3a9f194852c03299ae5664b5a425b43358e7a9eef2")
