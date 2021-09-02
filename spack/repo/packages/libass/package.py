from spack import *


class Libass(AutotoolsPackage):
    """libass is a portable subtitle renderer for the ASS/SSA 
    (Advanced Substation Alpha/Substation Alpha) subtitle format."""

    homepage = "https://github.com/libass/libass"
    url      = "https://github.com/libass/libass/releases/download/0.15.1/libass-0.15.1.tar.gz"

    maintainers = ['alexdotc']

    version('0.15.1', sha256='101e2be1bf52e8fc265e7ca2225af8bd678839ba13720b969883eb9da43048a6')
    version('0.15.0', sha256='9cbddee5e8c87e43a5fe627a19cd2aa4c36552156eb4edcf6c5a30bd4934fe58')
    version('0.14.0', sha256='8d5a5c920b90b70a108007ffcd2289ac652c0e03fc88e6eecefa37df0f2e7fdf')
    version('0.13.7', sha256='008a05a4ed341483d8399c8071d57a39853cf025412b32da277e76ad8226e158')
    version('0.13.6', sha256='62070da83b2139c1875c9db65ece37f80f955097227b7d46ade680221efdff4b')
    version('0.13.5', sha256='e5c6d9ae81c3c75721a3920960959d2512e2ef14666910d76f976589d2f89b3f')
    version('0.13.4', sha256='6711469df5fcc47d06e92f7383dcebcf1282591002d2356057997e8936840792')
    version('0.13.3', sha256='86c8c45d14e4fd23b5aa45c72d9366c46b4e28087da306e04d52252e04a87d0a')
    version('0.13.2', sha256='8baccf663553b62977b1c017d18b3879835da0ef79dc4d3b708f2566762f1d5e')
    version('0.13.1', sha256='9741b9b4059e18b4369f8f3f77248416f988589896fd7bf9ce3da7dfb9a84797')
