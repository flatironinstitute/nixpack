from spack.package import *


class Healpix(MakefilePackage):
    """Healpix is a library for calculating
    Hierarchical Equal Area isoLatitude Pixelation of a sphere."""

    homepage = "https://healpix.sourceforge.io"
    url = "https://downloads.sourceforge.net/project/healpix/Healpix_3.82/Healpix_3.82_2022Jul28.tar.gz"

    version("3.82", sha256="47629f057a2daf06fca3305db1c6950edb9e61bbe2d7ed4d98ff05809da2a127")

    depends_on("cfitsio")
    # depends_on("libsharp", type="build")

    def edit(self, spec, prefix):
        pass

    def install(self, spec, prefix):
        pass


    @run_before('build')
    def configure(self):
        spec = self.spec
        prefix = self.prefix
        
        # configure_fix = FileFilter("hpxconfig_functions.sh")
        # configure_fix.filter(
        #     r"makeTopConf\(\){",
        #     'makeTopConf(){ set',
        # )

        env = {}
        configure = Executable('./configure')
        configure(*self.configure_args(),
            extra_env=self.configure_env(spec),
            _dump_env=env,
        )
        # print(env)

        makedirs(prefix.lib)
        makedirs(prefix.include)

    def configure_args(self):
        return ['-L', '--auto=c']  #  ,cxx,f90,

    def configure_env(self, spec):
        return dict(
            SHELL='sh',
            C_SHARED='1',
            #FC
            #F_SHARED
            FITSDIR=spec['cfitsio'].prefix.lib,
            FITSINC=spec['cfitsio'].prefix.include,
            #PYTHON
        )
        
    @property
    def build_targets(self):
        prefix = self.prefix
        # Using the "build_targets" trick to pass command-line vars
        return [
            f'C_LIBDIR={prefix.lib}',
            f'C_INCDIR={prefix.include}'
        ]

    # def patch(self):
    #     spec = self.spec
    #     configure_fix = FileFilter("configure")
    #     # Link libsharp static libs
    #     configure_fix.filter(
    #         r"^SHARP_LIBS=.*$",
    #         'SHARP_LIBS="-L{0} -lsharp -lc_utils -lfftpack -lm"'.format(
    #             spec["libsharp"].prefix.lib
    #         ),
    #     )
