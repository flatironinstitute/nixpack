#!/bin/sh -eu
for f in setup.sh setup.csh lmodrc.lua site/SitePackage.lua site_msg.lua ; do
	/bin/mkdir -p $out/`/bin/dirname $f`
	/bin/sed "s:@LMOD@:$lmod:g;s:@MODS@:$mods:g;s:@CACHE@:$cache:g;s:@SITE@:$out:g" $src/`/bin/basename $f` > $out/$f
done
# just for convenience:
/bin/ln -s $mods $out
/bin/ln -s $lmod/lmod $out
