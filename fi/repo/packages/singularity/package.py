import os
import re
from spack import *
import spack.pkg.builtin.singularity

class Singularity(spack.pkg.builtin.singularity.Singularity):
    depends_on('e2fsprogs', type='run')

    @property
    def config_options(self):
        options = super().config_options
        options.remove('--without-conmon')
        return options

    @property
    def package_dir(self):
        return os.path.abspath(os.path.dirname(spack.pkg.builtin.singularity.__file__))

    @run_after('install')
    def fi_conf(self):
        conf_path = os.path.join(self.prefix.etc, "singularity", "singularity.conf")
        conf_keys = {
                'allow pid ns': 'no',
                'mount slave': 'no',
                'enable fusemount': 'no',
                'sessiondir max size': '64',
                'root default capabilities': 'no'
            }
        def conf_val(match):
            return match[1] + ' = ' + conf_keys[match[1]]
        filter_file(r'^\s*(' + '|'.join(map(re.escape, conf_keys.keys())) + ')\s*=.*$', conf_val, conf_path)

    def setup_run_environment(self, env):
        super().setup_run_environment(env)
        self.spec['e2fsprogs'].package.setup_run_environment(env)
