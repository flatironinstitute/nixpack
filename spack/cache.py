#!/bin/env python3

import os
import nixpack
import spack

spack.config.set('config:misc_cache', os.environ['out'], 'command_line')
spack.repo.path.all_package_names()
