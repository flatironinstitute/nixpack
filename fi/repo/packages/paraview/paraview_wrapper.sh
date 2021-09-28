#!/bin/bash

pvpython_vers=$(pvpython -c 'import platform; print(".".join(platform.python_version_tuple()[0:2]))')
python_vers=$(python3 -c 'import platform; print(".".join(platform.python_version_tuple()[0:2]))')

if test "$pvpython_vers" != "$python_vers"; then
    echo "Python3 version and paraview python version don't match. Not loading extra python libs into paraview..."
    echo "Load default python module and optional relevant virtual environment to extend paraview"
else
export PYTHONPATH=$(python3 <<EOF
import site
import os

pythonpath = ''
if 'PYTHONPATH' in os.environ:
   pythonpath = os.environ['PYTHONPATH'] + ":"

pythonpath += ':'.join(site.getsitepackages())
print(pythonpath)

EOF
)
fi

exec paraview-real "$@"
