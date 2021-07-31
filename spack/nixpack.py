import os
import sys

if not sys.executable: # why not?
    sys.executable = os.environ.pop('builder')

# would be nice to bootstrap things spack needs (like tar)
os.environ['PATH'] = '/bin:/usr/bin'

os.W_OK = 0 # hack hackity to disable writability checks (mainly for cache)

import spack.main # otherwise you get recursive import errors

spack.config.command_line_scopes = [os.environ.pop('spackConfig')]
cache = os.environ.pop('spackCache', None)
if cache:
    spack.config.set('config:misc_cache', cache, 'command_line')
