import sys
import spack.pkg.builtin.papi as builtin

class Papi(builtin.Papi):
    version('6.0.0.1-fi', commit='73c4b98d40e334ed011be7033a30fe201f5e38a8')
    patch('icelake_events.patch', when='@6.0.0.1-fi')
