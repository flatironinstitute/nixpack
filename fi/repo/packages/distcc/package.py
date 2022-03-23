import sys
import spack.pkg.builtin.distcc as builtin

class Distcc(builtin.Distcc):
    version('3.3.5', sha256='13a4b3ce49dfc853a3de550f6ccac583413946b3a2fa778ddf503a9edc8059b0')
