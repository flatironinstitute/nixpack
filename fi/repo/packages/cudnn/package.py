from spack.package import *
import spack.pkg.builtin.cudnn as builtin

class Cudnn(builtin.Cudnn):
    version("8.9.2.26-11.x",
            url="file:///mnt/sw/pkg/cudnn-linux-x86_64-8.9.2.26_cuda11-archive.tar.xz",
            sha256='39883d1bcab4bd2bf3dac5a2172b38533c1e777e45e35813100059e5091406f6',
            )
    version("8.9.2.26-12.x",
            url="file:///mnt/sw/pkg/cudnn-linux-x86_64-8.9.2.26_cuda12-archive.tar.xz",
            sha256='ccafd7d15c2bf26187d52d79d9ccf95104f4199980f5075a7c1ee3347948ce32',
            )
    
    depends_on('cuda@11', when='@8.9.2.26-11.x')
    depends_on('cuda@12', when='@8.9.2.26-12.x')
