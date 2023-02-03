from spack.package import *


class Healpix(MakefilePackage):
    """Healpix is a library for calculating
    Hierarchical Equal Area isoLatitude Pixelation of a sphere."""

    homepage = "https://healpix.sourceforge.io"
    url = "https://downloads.sourceforge.net/project/healpix/Healpix_3.82/Healpix_3.82_2022Jul28.tar.gz"

    version("3.82", sha256="47629f057a2daf06fca3305db1c6950edb9e61bbe2d7ed4d98ff05809da2a127")

    depends_on("cfitsio")

    def edit(self, spec, prefix):
        config = FileFilter('hpxconfig_functions.sh')
        config.filter(r'^\s*SHARPPREFIX=.*', f'SHARPPREFIX={prefix}')
        config.filter(r'^\s*CXXPREFIX=.*', f'CXXPREFIX={prefix}')
        config.filter(r'SHARP_LIBS="[^"]*"', f'SHARP_LIBS="-L{prefix.lib} -lsharp"')
        config.filter(r'SHARP_CFLAGS="[^"]*"', f'SHARP_CFLAGS="-I{prefix.include}"')

    @run_before('build')
    def configure(self):
        spec = self.spec

        configure = Executable('./configure')
        configure(*self.configure_args(),
            extra_env=self.configure_env(spec),
        )

    def configure_args(self):
        return ['-L', '--auto=c,cxx']

    def configure_env(self, spec):
        return dict(
            SHELL='sh',
            C_SHARED='1',
            FITSDIR=spec['cfitsio'].prefix.lib,
            FITSINC=spec['cfitsio'].prefix.include,
            SHARP_COPT='-O3 -ffast-math',
        )
        
    @property
    def build_targets(self):
        prefix = self.prefix
        # Using the "build_targets" trick to pass command-line vars
        return [
            f'C_LIBDIR={prefix.lib}',
            f'C_INCDIR={prefix.include}'
        ]

    def install(self, spec, prefix):
        pass
