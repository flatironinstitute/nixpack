# Adapted from Spack's built-in Rockstar

from spack.package import *


class Rockstar(MakefilePackage):
    """The Rockstar halo finder"""

    homepage = "https://bitbucket.org/gfcstanford/rockstar"    

    # main repo
    version("main.2021-09-04.36ce9e",
        git = 'https://bitbucket.org/gfcstanford/rockstar.git',
        commit = '36ce9eea36eeda4c333acf56f8bb0d40ff0df2a1',
        preferred=True,
    )
    # awetzel's rockstar-galaxies fork
    version("galaxies.2022-12-29.a9d865",
        git = 'https://bitbucket.org/awetzel/rockstar-galaxies.git',
        commit = 'a9d8653c0aabc1ba31646e504c2d37013ffd11d4',
    )

    variant("hdf5", description="HDF5 support", default=True)

    depends_on("hdf5", when="+hdf5")
    depends_on('libtirpc')

    patch('0001-Fix-to-solve-linking-problem-with-gcc-10.patch',
        when='@galaxies',
    )

    def patch(self):
        oflags = ' '.join(self.extra_oflags())
        filter_file(
            r'^(OFLAGS\s*=[^#\n]*)',
            rf'\1 {oflags}',
            'Makefile',
        )
        filter_file(
            r'(-D_BSD_SOURCE|-D_SVID_SOURCE)',
            r'-D_DEFAULT_SOURCE',
            'Makefile',
        )
        filter_file(
            r'^CC\s*=.*',
            r'',
            'Makefile',
        )

    def extra_oflags(self):
        return ['-ltirpc']

    def install(self, spec, prefix):
        # install the entire repo
        # probably only the binaries will be used, though
        install_tree('.', prefix)

        mkdirp(prefix.bin)
        mkdirp(prefix.lib)

        util = ['util/bgc2_to_ascii',
                'util/find_parents',
                'util/finish_bgc2',
                'util/subhalo_stats',
                ]
        for fn in util:
            install(fn, prefix.bin)
        
        if '@galaxies' in spec:
            install('rockstar-galaxies', prefix.bin)
            install('librockstar-galaxies.so', prefix.lib)
        else:
            install('rockstar', prefix.bin)
            install('librockstar.so', prefix.lib)

    @property
    def build_targets(self):
        targets = [
            'lib',
            'bgc2',
            'parents',
            'substats'
        ]
        if '+hdf5' in self.spec:
            targets += ['with_hdf5']
        else:
            targets += ['all']
        return targets
