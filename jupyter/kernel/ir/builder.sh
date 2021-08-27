#!/bin/sh
HOME=$TMPDIR PATH=/bin:$pkg/bin:$jupyter/bin R_LIBS_SITE=$pkg/rlib/R/library $pkg/bin/R --vanilla -f $rBuilder
