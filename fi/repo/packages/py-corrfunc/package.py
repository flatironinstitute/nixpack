# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.package import *


class PyCorrfunc(PythonPackage):
    """Blazing fast correlation functions on the CPU"""

    homepage = "https://corrfunc.readthedocs.io/"
    pypi = "Corrfunc/Corrfunc-2.5.0.tar.gz"

    maintainers("lgarrison")

    version("2.5.0", sha256="91c41ef0266daf644ba19ecd9d536a82018bd0d596854f0607d9e7485cfcfb95")

    depends_on("python@3.5:", type=("build", "run"))
    depends_on("py-setuptools", type="build")

    depends_on("gmake")
    depends_on("py-numpy@1.7:", type=("build", "run"))
    depends_on("py-future", type=("build", "run"))
    depends_on("py-wurlitzer", type=("build", "run"))
    depends_on("gsl@2.4:", type=("build", "run"))

    def patch(self):
        filter_file(
            '-march=native',
            '',
            'common.mk'
        )

    def global_options(self, spec, prefix):
        options = ['CC=cc']
        return options
