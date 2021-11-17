#!/bin/sh -eu
render() {
	/bin/sed "s:@LMOD@:$lmod:g;s:@MODS@:$mods:g;s:@CACHE@:$cache:g;s:@SITE@:$out:g;s!@DATE@!`/bin/date`!g;s:@GIT@:$git:g" "$@"
}

if [[ -z $mod ]] ; then
	render $src/modules.lua > $out
	exit 0
fi

for f in setup.sh setup.csh lmodrc.lua site/SitePackage.lua site_msg.lua ; do
	/bin/mkdir -p $out/`/bin/dirname $f`
	render $src/`/bin/basename $f` > $out/$f
done
/bin/ln -s $mod $out/modules.lua
/bin/ln -s $mods $out
/bin/ln -s $lmod/lmod $out
