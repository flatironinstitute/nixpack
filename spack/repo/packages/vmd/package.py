from spack import *
import spack.pkg.builtin.vmd


class Vmd(spack.pkg.builtin.vmd.Vmd):
    # fix hash
    version('1.9.3', sha256='9427a7acb1c7809525f70f635bceeb7eff8e7574e7e3565d6f71f3d6ce405a71',
            url='file:///mnt/home/spack/vmd-1.9.3.bin.LINUXAMD64-CUDA8-OptiX4-OSPRay111p1.opengl.tar.gz')
    manual_download = False

    depends_on('gcc', type=('run', 'link'))

    def install(self, spec, prefix):
        with working_dir(join_path(self.stage.source_path, 'src')):
            make('install')

        # make sure the executable finds and uses the Spack-provided
        # libraries, otherwise the executable may or may not run depending
        # on what is installed on the host
        patchelf = which('patchelf')
        rpaths = [self.spec[dep].libs.directories[0]
            for dep in ['libx11', 'libxi', 'libxinerama', 'gl']]
        rpaths.append(join_path(self.spec['gcc'].prefix, 'lib64'))
        rpath = ':'.join(rpaths)
        patchelf('--set-rpath', rpath,
                 join_path(self.prefix, 'lib64', 'vmd_LINUXAMD64'))
