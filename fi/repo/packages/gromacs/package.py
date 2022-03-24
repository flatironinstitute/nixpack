import spack.pkg.builtin.gromacs as builtin

class Gromacs(builtin.Gromacs):
    version('2022', sha256='fad60d606c02e6164018692c6c9f2c159a9130c2bf32e8c5f4f1b6ba2dda2b68')
    depends_on('plumed@2.8.0+mpi', when='@2021.4+plumed+mpi')
    depends_on('plumed@2.8.0~mpi', when='@2021.4+plumed~mpi')
