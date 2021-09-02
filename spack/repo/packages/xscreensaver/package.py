from spack import *


class Xscreensaver(AutotoolsPackage):
    """Xscreensaver package"""

    homepage = "https://www.jwz.org"
    url      = "https://www.jwz.org/xscreensaver/xscreensaver-6.01.tar.gz"

    maintainers = ['alexdotc']

    version('6.01', sha256='085484665d91f60b4a1dedacd94bcf9b74b0fb096bcedc89ff1c245168e5473b')

    @run_before('configure')
    def fix_GTK_paths(self):
        filter_file(r'(@GTK_DATADIR@)|(@PO_DATADIR@)', '@datadir@', 
                    'driver/Makefile.in', 'po/Makefile.in.in')
        

    def configure_args(self):
        args = ['--with-app-defaults='+prefix.share]
        return args
