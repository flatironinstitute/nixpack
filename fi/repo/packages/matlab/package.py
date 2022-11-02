from spack import *
import spack.pkg.builtin.matlab

class Matlab(spack.pkg.builtin.matlab.Matlab):
    version('R2022b', sha256='a704ce9123752b93e210b2114b5e0f698a92e98d6569b97f0b499455d5258746')
    manual_download = False

    def url_for_version(self, version):
        return "file:///mnt/sw/pkg/matlab_{0}_glnxa64.zip".format(version)

    def install(self, spec, prefix):
        super().install(spec, prefix)
        # prevent post_install crash
        with working_dir(self.spec.prefix.bin.glnxa64):
            touch("libSDL2.so")
