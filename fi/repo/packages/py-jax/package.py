from spack import *
import os
import pickle

class PyJax(PythonPackage, CudaPackage):
    """JAX is Autograd and XLA, brought together for high-performance machine learning research."""

    homepage = "https://github.com/google/jax"
    url      = "https://github.com/google/jax/archive/refs/tags/jax-v0.2.20.tar.gz"

    version('0.2.20', sha256='2e40bd8e2493a3609177b122c583636c0c88c5e695f8041190eefdfd42a6fc5b')

    variant('cuda', default=True, description='Build with CUDA support')

    depends_on('python@3.7:', type=('build', 'run'))
    depends_on('py-setuptools', type='build')
    depends_on('py-numpy@1.18:', type=('build', 'run'))
    depends_on('py-scipy@1.2.1:', type=('build', 'run'))
    depends_on('py-absl-py', type='build')
    depends_on('py-cython', type=('build'))
    depends_on('py-opt-einsum', type='build')
    depends_on('cudnn', type=('build', 'link', 'run'), when='+cuda')
    depends_on('bazel', type=('build'))
    patch('bazel_call.patch')

    conflicts('cuda_arch=none', when='+cuda', msg='Must specify CUDA compute capabilities of your GPU, see https://developer.nvidia.com/cuda-gpus')

    def patch(self):
        capabilities = ','.join('{0:.1f}'.format(
            float(i) / 10.0) for i in self.spec.variants['cuda_arch'].value)
        filter_file(r'TF_CUDA_COMPUTE_CAPABILITIES="[^"]*"',
                'TF_CUDA_COMPUTE_CAPABILITIES="{0}"'.format(capabilities),
                '.bazelrc')

    def build(self, spec, prefix):
        pythonargs = ['build/build.py',
                      '--bazel_options=--jobs=' + str(make_jobs)]
        if spec.satisfies('+cuda'):
            pythonargs.extend([
                      '--enable_cuda',
                      '--cuda_path=' + spec['cuda'].prefix,
                      '--cudnn_path=' + spec['cudnn'].prefix])
        python(*pythonargs)

        with open('.jax_configure.bazelrc', 'a') as f:
            f.write('build --action_env PYTHONPATH="{0}"\n'.format(env['PYTHONPATH']))

        with working_dir('build'):
            with open('bazel_args', 'r') as f:
                bazelargs = [l.rstrip('\n') for l in f]
            bazel(*bazelargs)
