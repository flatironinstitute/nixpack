# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.package import *


class PyPymc(PythonPackage):
    """Probabilistic Programming in Python: Bayesian Modeling and Probabilistic Machine Learning with PyTensor
    """

    homepage = "http://github.com/pymc-devs/pymc"
    pypi = "pymc/pymc-5.5.0.tar.gz"

    version("5.5.0", sha256="7fe2ac72de8a5d04b76566fa44f64a400d67939c8393e6487d8a99f920f4f277")

    depends_on("python@3.8:", type=("build", "run"))

    depends_on("py-setuptools", type="build")

    depends_on("py-arviz@0.13:", type=("build", "run"))
    depends_on("py-cachetools@4.2.1:", type=("build", "run"))
    depends_on("py-cloudpickle", type=("build", "run"))
    depends_on("py-fastprogress@0.2.0:", type=("build", "run"))
    depends_on("py-numpy@1.15:", type=("build", "run"))
    depends_on("py-pandas@0.24:", type=("build", "run"))
    depends_on("py-pytensor@2.12.0:2.12", type=("build", "run"))
    depends_on("py-scipy@1.4.1:", type=("build", "run"))
    depends_on("py-typing-extensions@3.7.4:", type=("build", "run"))
