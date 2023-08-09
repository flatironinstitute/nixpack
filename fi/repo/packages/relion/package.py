
from spack.package import *
import spack.pkg.builtin.relion as builtin

class Relion(builtin.Relion):

    version("4.0.1",
            sha256="7e0d56fd4068c99f943dc309ae533131d33870392b53a7c7aae7f65774f667be",
    )
