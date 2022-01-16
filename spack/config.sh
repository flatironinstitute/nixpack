#!/bin/sh -eu

mkdir -p $out
for section in $sections ; do
	eval "echo \"\$$section\"" > $out/$section.yaml
done
