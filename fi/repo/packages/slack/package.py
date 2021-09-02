from spack import *
from shutil import move
from os import getcwd
from os.path import join

class Slack(Package):
    """FI Slack no-sandbox"""

    url      = join(spack.config.get("config:source_cache"), "slack/slack-4.17.0-0.1.fc21.x86_64.tar.xz")

    maintainers = ['alexdotc']

    version('4.17.0-0.1.fc21', sha256='6657bad3c0532c606c3fb32b03800167c7c533684c848431101b88524656254f')

    def install(self, spec, prefix):
        move(getcwd(), prefix)
