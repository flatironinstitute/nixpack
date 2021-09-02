import sys
# somehow the package doesn't resolve correctly in some environments...
try:
    builtin = sys.modules['spack.pkg.builtin.hdf5']
except KeyError:
    import spack.pkg.builtin.hdf5 as builtin

class Hdf5(builtin.Hdf5):
    # Several functions were removed from openmpi>=3, so replace those function calls with
    # supported ones
    patch('hdf5-1.8.21-openmpi4.patch', when='@1.8.21+mpi', sha256=None)

    def configure_args(self):
        extra_args = super().configure_args()

        # Fix for gcc@10 compile issues
        if self.spec.satisfies('@1.8.0:1.8.999%gcc@10:'):
            extra_args.extend([
                'FCFLAGS=-fallow-invalid-boz',
            ])

        return extra_args
