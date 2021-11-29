#!/bin/sh -eu
/bin/sed "s:@MODS@:$mods:g;s!@DATE@!`/bin/date`!g;s:@GIT@:$git:g" $src > $out
