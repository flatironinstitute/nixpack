# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

import spack.pkg.builtin.fgsl as builtin
from spack.package import *


class Fgsl(builtin.Fgsl):

    version("1.5.0",
        url="https://github.com/reinh-bader/fgsl/archive/1.5.0.tar.gz",
        sha256="5013b4e000e556daac8b3c83192adfe8f36ffdc91d1d4baf0b1cb3100260e664",
        )

    # 1.5 works with GSL 2.6, and future versions too, it seems?
    depends_on("gsl@2.6:", when="@1.5.0")
