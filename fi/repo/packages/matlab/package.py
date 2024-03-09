from spack import *
import spack.pkg.builtin.matlab

class Matlab(spack.pkg.builtin.matlab.Matlab):
    version('R2023b', sha256='9da5eaf76d3677101c580174e2e795045e9d0ae31bb7f2cdc1af8bd19da58518')
    version('R2023a', sha256='42d501b2c53a29994f7d09c167bb9857f03335e000ee0e3d3e32ad4aede6fee5')
    version('R2022b', sha256='a704ce9123752b93e210b2114b5e0f698a92e98d6569b97f0b499455d5258746')
    manual_download = False

    def url_for_version(self, version):
        return "file:///mnt/sw/pkg/matlab_{0}_glnxa64.zip".format(version)

    def install(self, spec, prefix):
        super().install(spec, prefix)
        # prevent post_install crash
        with working_dir(self.spec.prefix.bin.glnxa64):
            touch("libSDL2.so")
