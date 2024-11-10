#!/bin/env python3

import os
import nixpack
import spack

spack.config.set('config:misc_cache', os.environ['out'], 'nixpack')
print("Prepopulating spack repo cache...")
spack.repo.PATH.all_package_names()
