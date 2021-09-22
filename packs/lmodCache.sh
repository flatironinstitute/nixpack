#!/bin/sh
$lmod/lmod/lmod/libexec/update_lmod_system_cache_files -d $out/cacheDir -t $out/cacheTS.txt $MODULEPATH
cat > $out/lmodrc.lua <<EOF
scDescriptT = {
  {
    ["dir"]       = "$out/cacheDir",
    ["timestamp"] = "$out/cacheTS.txt",
  },
}
EOF
