from spack import *
import spack.pkg.builtin.vmd


class Vmd(spack.pkg.builtin.vmd.Vmd):
    # fix hash
    version('1.9.3', sha256='9427a7acb1c7809525f70f635bceeb7eff8e7574e7e3565d6f71f3d6ce405a71',
            url='file:///mnt/home/spack/vmd-1.9.3.bin.LINUXAMD64-CUDA8-OptiX4-OSPRay111p1.opengl.tar.gz')
    manual_download = False
