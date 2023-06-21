from spack.package import *
import spack.pkg.builtin.cudnn as builtin

class Cudnn(builtin.Cudnn):
    version("8.9.1.23-11.8",
            url="file:///mnt/sw/pkg/cudnn-linux-x86_64-8.9.1.23_cuda11-archive.tar.xz",
            sha256='a6d9887267e28590c9db95ce65cbe96a668df0352338b7d337e0532ded33485c',
            )
    version("8.9.1.23-12.0",
            url="file:///mnt/sw/pkg/cudnn-linux-x86_64-8.9.1.23_cuda12-archive.tar.xz",
            sha256='35163c5c542be0c511738b27e25235193cbeedc5e0e006e44b1cdeaf1922e83e',
            )
    
    depends_on('cuda@11', when='@8.9.1.23-11.8')
    depends_on('cuda@12', when='@8.9.1.23-12.0')
