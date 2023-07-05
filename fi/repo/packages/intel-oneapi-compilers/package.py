from spack.package import *
import spack.pkg.builtin.intel_oneapi_compilers as builtin


class IntelOneapiCompilers(builtin.IntelOneapiCompilers):

    variant("codeplay", default=True, when="@2023.1.0")

    @property
    def codeplay_installers(self):
        return [
            '/mnt/sw/pkg/oneapi-for-nvidia-gpus-2023.1.0-cuda-12.0-linux.sh',
            '/mnt/sw/pkg/oneapi-for-amd-gpus-2023.1.0-rocm-5.4.3-linux.sh',
        ]

    @run_after("install", when="+codeplay")
    def install_codeplay(self):
        for fn in self.codeplay_installers:
            installer = Executable(fn)
            installer(f"--install-dir", self.prefix, "-y")
