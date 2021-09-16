from spack import *
import os
import pickle

class PyJax(PythonPackage):
    """JAX is Autograd and XLA, brought together for high-performance machine learning research."""

    homepage = "https://github.com/google/jax"
    url      = "https://github.com/google/jax/archive/refs/tags/jax-v0.2.20.tar.gz"

    version('0.2.20', sha256='2e40bd8e2493a3609177b122c583636c0c88c5e695f8041190eefdfd42a6fc5b')

    depends_on('python@3.7:', type=('build', 'run'))
    depends_on('py-setuptools', type='build')
    depends_on('py-numpy@1.18:', type=('build', 'run'))
    depends_on('py-scipy@1.2.1:', type=('build', 'run'))
    depends_on('py-absl-py', type='build')
    depends_on('py-cython', type=('build'))
    depends_on('py-opt-einsum', type='build')
    depends_on('cuda', type=('build', 'link', 'run'))
    depends_on('cudnn', type=('build', 'link', 'run'))
    depends_on('bazel', type=('build'))
    patch('bazel_call.patch')

    def setup_build_environment(self, env):
        env.set('TEST_TMPDIR', join_path(self.stage.source_path, 'bazel-cache'))

    def build(self, spec, prefix):
        pythonargs = ['build/build.py',
                      '--enable_cuda',
                      '--cuda_path=' + spec['cuda'].prefix,
                      '--cudnn_path=' + spec['cudnn'].prefix]
        python(*pythonargs)

        os.chdir('build')
        bazelargs = pickle.load(open('bazel_args.pickle', 'rb'))
        print(bazelargs)
        bazel(*bazelargs)
