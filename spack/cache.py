#!/bin/env python3

import os
import sys

os.environ['PATH'] = '/bin:/usr/bin'

import spack.main # because otherwise you get recursive import errors

spack.config.command_line_scopes = [os.environ['spackConfig']]
spack.config.set('config:misc_cache', os.environ['out'], 'command_line')
spack.repo.path.all_package_names()
