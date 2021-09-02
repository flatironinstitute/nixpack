from spack import *

class Mplayer(AutotoolsPackage):
    """MPlayer is a movie player which runs on many systems (see the documentation). 
       It plays most MPEG/VOB, AVI, Ogg/OGM, VIVO, ASF/WMA/WMV, QT/MOV/MP4, RealMedia, 
       Matroska, NUT, NuppelVideo, FLI, YUV4MPEG, FILM, RoQ, PVA files, supported by many 
       native, XAnim, and Win32 DLL codecs. You can watch VideoCD, SVCD, DVD, 3ivx, 
       DivX 3/4/5, WMV and even H.264 movies."""

    homepage = "https://www.mplayerhq.hu"
    url      = "http://www.mplayerhq.hu/MPlayer/releases/MPlayer-1.4.tar.xz"

    version('1.4',   sha256='82596ed558478d28248c7bc3828eb09e6948c099bbd76bb7ee745a0e3275b548')
    version('1.3.0', sha256='3ad0846c92d89ab2e4e6fb83bf991ea677e7aa2ea775845814cbceb608b09843')
    version('1.2.1', sha256='831baf097d899bdfcdad0cb80f33cc8dff77fa52cb306bee5dee6843b5c52b5f')
    version('1.2',   sha256='ffe7f6f10adf2920707e8d6c04f0d3ed34c307efc6cd90ac46593ee8fba2e2b6')
    version('1.1.1', sha256='ce8fc7c3179e6a57eb3a58cb7d1604388756b8a61764cc93e095e7aff3798c76')
    version('1.1',   sha256='76cb47eadb52b420ca028276ebd8112114ad0ab3b726af60f07fb2f39dae6c9c')
