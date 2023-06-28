# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.package import *


class PyYpyWebsocket(PythonPackage):
    """WebSocket connector for Ypy"""

    homepage = "https://github.com/y-crdt/ypy-websocket"
    pypi = "ypy_websocket/ypy_websocket-0.8.2.tar.gz"

    version("0.8.2", sha256="491b2cc4271df4dde9be83017c15f4532b597dc43148472eb20c5aeb838a5b46")

    depends_on("python@3.7:", type=("build", "run"))

    depends_on("py-hatchling", type="build")

    depends_on("py-aiofiles@22.1.0:22", type=("build", "run"))
    depends_on("py-aiosqlite@0.17.0:0", type=("build", "run"))
    depends_on("py-y-py@0.5.3:0.5", type=("build", "run"))
