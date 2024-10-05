import os
import re
from spack import *
import spack.pkg.builtin.apptainer

class Apptainer(spack.pkg.builtin.apptainer.Apptainer):
    depends_on('e2fsprogs', type='run')

    @run_after('install')
    def fi_conf(self):
        conf_path = os.path.join(self.prefix.etc, "apptainer", "apptainer.conf")
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
