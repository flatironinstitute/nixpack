#!/bin/sh -eu
/bin/mkdir -p $out
/bin/ln -s $mod $out/modules.lua
# these are just temporary stubs until /etc/profile.d/modules.sh is updated everywhere:
for f in setup.sh setup.csh ; do
	/bin/cp $src/$f $out/$f
done
