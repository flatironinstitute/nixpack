MODULEPATH_DEFAULT=@MODS@/Core
export LMOD_PACKAGE_PATH=@SITE@/site
export LMOD_RC=@SITE@/lmodrc.lua
export LMOD_SITE_MSG_FILE=@SITE@/site_msg.lua
export LMOD_AVAIL_STYLE='system:<trim>:group'
# TODO: working around configuration bug (remove when fixed):
export LMOD_AVAIL_EXTENSIONS=no

if [[ -z $MODULEPATH || $MODULEPATH = /cm/shared/sw/modules ]] ; then
  MODULEPATH=$MODULEPATH_DEFAULT
elif [[ :$MODULEPATH: != *:$MODULEPATH_DEFAULT:* ]] ; then
  MODULEPATH=$MODULEPATH:$MODULEPATH_DEFAULT
fi
unset MODULEPATH_DEFAULT
export MODULEPATH

. @LMOD@/lmod/lmod/init/profile
if [[ -z $__Init_Default_Modules ]]; then
  export __Init_Default_Modules=1
  # TODO: do we want to set defaults in another way?
  export LMOD_SYSTEM_DEFAULT_MODULES=${LMOD_SYSTEM_DEFAULT_MODULES:-slurm:openblas}
  module --initial_load restore
else
  module refresh
fi
