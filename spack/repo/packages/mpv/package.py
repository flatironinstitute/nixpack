from spack import *

class Mpv(WafPackage):
    """MPV media player"""

    homepage = "https://mpv.io"
    url      = "https://github.com/mpv-player/mpv/archive/refs/tags/v0.33.1.tar.gz"

    maintainers = ['alexdotc']

    version('0.33.1', sha256='100a116b9f23bdcda3a596e9f26be3a69f166a4f1d00910d1789b6571c46f3a9')

    depends_on('libass')
    depends_on('ffmpeg')
    
    @run_before('configure')
    def get_waf(self):
        python('bootstrap.py')
