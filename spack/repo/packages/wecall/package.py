from spack.package import *

class Wecall(MakefilePackage):
    """Fast, accurate and simple to use command line tool for variant detection in NGS data. """

    url      = "https://github.com/Genomicsplc/wecall/archive/refs/tags/v2.0.0.tar.gz"

    version('2.0.0', sha256='c67cc7ca686432e4438ceb9160f698394e4d21734baa97bc3fc781065d59b410')

    patch('cmake-rhel-regex.patch')
    patch('ncurses.patch')

    depends_on('ncurses')
    depends_on('zlib')
    depends_on('boost+regex+test')
    depends_on('cmake', type='build')
    depends_on('texlive', type='build')
    depends_on('python', type='build')

    def install(self, spec, prefix):
        doc = join_path(prefix, 'share/doc/wecall')
        bin = join_path(prefix, 'bin')
        mkdirp(doc)
        mkdirp(bin)
        with working_dir(join_path(self.stage.source_path, 'build')):
            copy("weCall", bin)
            copy("weCall-userguide.pdf", doc)
