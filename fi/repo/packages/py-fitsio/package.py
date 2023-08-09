# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.package import *


class PyFitsio(PythonPackage):
    """A python package for FITS input/output wrapping cfitsio"""

    homepage = "https://github.com/esheldon/fitsio"
    pypi = "fitsio/fitsio-1.1.8.tar.gz"

    version("1.1.8", sha256="61f569b2682a0cadce52c9653f0c9b81f951d000522cef645ce1cb49f78300f9")

    depends_on("py-setuptools", type=("build", "run"))

    depends_on("py-numpy", type=("build", "run"))
    depends_on("cfitsio@3.49", type=("build", "link", "run"))

    def patch(self):
        filter_file(r'self\.use_system_fitsio =.*',
                    'self.use_system_fitsio = True',
                    'setup.py',
        )

        filter_file(r'self.system_fitsio_includedir =.*',
                    f'self.system_fitsio_includedir = "{self.spec["cfitsio"].prefix.include}"',
                    'setup.py'
        )

        filter_file(r'self.system_fitsio_libdir =.*',
                    f'self.system_fitsio_libdir = "{self.spec["cfitsio"].prefix.lib}"',
                    'setup.py'
        )
