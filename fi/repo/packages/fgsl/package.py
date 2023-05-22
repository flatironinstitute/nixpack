# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.package import *

#
# Author: Gilbert Brietzke
# Date: June 18, 2019

class Fgsl(AutotoolsPackage):
    """Fortran interface to the GNU Scientific Library"""

    homepage = "https://github.com/reinh-bader/fgsl"
    url = "https://github.com/reinh-bader/fgsl/archive/v1.2.0.tar.gz"

    version("1.5.0",
        url="https://github.com/reinh-bader/fgsl/archive/1.5.0.tar.gz",
        sha256="5013b4e000e556daac8b3c83192adfe8f36ffdc91d1d4baf0b1cb3100260e664",
        )

    # 1.5 works with GSL 2.6, and future versions too, it seems?
    depends_on("gsl@2.6:", when="@1.5.0")

    depends_on("autoconf", type="build")
    depends_on("automake", type="build")
    depends_on("libtool", type="build")
    depends_on("m4", type="build")
    depends_on("pkgconfig", type="build")

    parallel = False

    @run_before("autoreconf")
    def create_m4_dir(self):
        mkdir("m4")

    def setup_build_environment(self, env):
        if self.compiler.name == "gcc":
            env.append_flags("FCFLAGS", "-ffree-line-length-none")
