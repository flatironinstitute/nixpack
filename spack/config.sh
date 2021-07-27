#!/bin/sh -eu

/bin/mkdir -p $out
for section in $sections ; do
	eval "echo \"\$$section\"" > $out/$section.yaml
done
