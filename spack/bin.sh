#!/bin/sh
gen() {

cat <<EOF
#!$SPACK_PYTHON
import os
import sys
EOF
for v in system os PATH SPACK_PYTHON spackConfig spackCache NIX_BUILD_TOP NIX_STORE ; do
	echo -n "os.environ['$v'] = "
	eval "echo \'\"\$$v\"\'"
done
cat << EOF
sys.path[:0] = ['$spackNixLib', '$spack/lib/spack', '$spack/lib/spack/external']
import nixpack
import spack.main
if __name__ == "__main__":
    sys.exit(spack.main.main())
EOF

}
gen > $out
/bin/chmod +x $out
