# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.package import *
import spack.pkg.builtin.py_arviz as builtin

class PyArviz(builtin.PyArviz):

    version("0.15.1", sha256="981cce0282bdf6f3b379255b95a440979f9a0ef0ae9dd88a54f763cf5b31484c")

    with when("@0.15.1"):
        depends_on("py-setuptools@60:", type="build")
    
        depends_on("py-matplotlib@3.2:", type=("build","run"))
        depends_on("py-numpy@1.20.0:", type=("build","run"))
        depends_on("py-scipy@1.8.0:", type=("build","run"))
        depends_on("py-pandas@1.3.0:", type=("build","run"))
        depends_on("py-xarray@0.21.0:", type=("build","run"))
        depends_on("py-h5netcdf@1.0.2:", type=("build","run"))
        depends_on("py-typing-extensions@4.1.0:", type=("build","run"))
        depends_on("py-xarray-einstats@0.3:", type=("build","run"))
