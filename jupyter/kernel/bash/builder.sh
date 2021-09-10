#!/bin/sh -e
pypath=($pkg/lib/python*/site-packages)
PYTHONPATH=$pypath $jupyter/bin/python -m bash_kernel.install --prefix $out
