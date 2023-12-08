from spack import *
import spack.pkg.builtin.py_numpy

class PyNumpy(spack.pkg.builtin.py_numpy.PyNumpy):

    def install(self, spec, prefix):
        # Skip if no BLAS/LAPACK requested
        spec = self.spec
        if spec['blas'].name != 'flexiblas':
            return super().install(spec, prefix)

        def write_library_dirs(f, dirs):
            f.write('library_dirs = {0}\n'.format(dirs))
            f.write('runtime_library_dirs = {0}\n'.format(dirs))

        blas_libs = spec['blas'].libs
        blas_headers = spec['blas'].headers
        lapack_libs = spec['lapack'].libs
        lapack_headers = spec['lapack'].headers

        lapackblas_libs = lapack_libs + blas_libs
        lapackblas_headers = lapack_headers + blas_headers

        blas_lib_names   = ','.join(blas_libs.names)
        blas_lib_dirs    = ':'.join(blas_libs.directories)
        blas_header_dirs = ':'.join(blas_headers.directories)

        lapack_lib_names   = ','.join(lapack_libs.names)
        lapack_lib_dirs    = ':'.join(lapack_libs.directories)
        lapack_header_dirs = ':'.join(lapack_headers.directories)

        # Tell numpy where to find BLAS/LAPACK libraries
        with open('site.cfg', 'w') as f:
            f.write('[atlas]\n')
            f.write('libraries = {0}\n'.format(blas_lib_names))
            write_library_dirs(f, blas_lib_dirs)
            f.write('include_dirs = {0}\n'.format(blas_header_dirs))

            f.write('[lapack]\n')
            f.write('libraries = {0}\n'.format(lapack_lib_names))
            write_library_dirs(f, lapack_lib_dirs)
            f.write('include_dirs = {0}\n'.format(lapack_header_dirs))

        super().install(spec, prefix)


    def setup_build_environment(self, env):
        super().setup_build_environment(env)
        if self.spec['blas'].name != 'flexiblas':
            return
        env.set('NPY_BLAS_ORDER', 'atlas')
        env.set('NPY_LAPACK_ORDER', 'atlas')
