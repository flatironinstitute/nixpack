# Copyright 2013-2020 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

# ----------------------------------------------------------------------------
# If you submit this package back to Spack as a pull request,
# please first remove this boilerplate and all FIXME comments.
#
# This is a template package file for Spack.  We've put "FIXME"
# next to all the things you'll want to change. Once you've handled
# them, you can save this file and test your package like this:
#
#     spack install py-kvsstcp
#
# You can edit this file again by typing:
#
#     spack edit py-kvsstcp
#
# See the Spack documentation for more information on packaging.
# ----------------------------------------------------------------------------

from spack import *


class PyKvsstcp(PythonPackage):
    """Key value storage server"""

    homepage = "https://github.com/flatironinstitute/kvsstcp"
    url      = "https://github.com/flatironinstitute/kvsstcp/archive/refs/tags/1.1.tar.gz"

    version('1.2', sha256='022ac2c03234dc9e3a921edf6015caa246fa7faf3ec0bf70511fc1bc94036cf5')
    version('1.1', sha256='c2ffc1077055626610995d71bad9028da03181a3e4c89a3c0eda0c9db8d06fe5')

    depends_on('py-setuptools', type='build')
