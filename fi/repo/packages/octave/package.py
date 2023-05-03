from spack.package import *
import spack.pkg.builtin.octave as builtin

class Octave(builtin.Octave):

    depends_on("pcre2", when="@8:")
