from spack.package import *
import spack.pkg.builtin.go as builtin

class Go(builtin.Go):

    def setup_build_environment(self, envmod):
        envmod.set('GOCACHE', join_path(env['TMP'], 'gocache'))
        super().setup_build_environment(envmod)
