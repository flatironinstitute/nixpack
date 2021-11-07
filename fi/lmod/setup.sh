if [[ -z $ENABLE_LMOD ]] ; then
  export ENABLE_LMOD=1
fi

if [[ $ENABLE_LMOD = 1 ]] ; then
  MODULEPATH_DEFAULT=@MODS@/Core
else
  MODULEPATH_DEFAULT=/cm/shared/sw/modules
fi

if [[ -z $MODULEPATH || $MODULEPATH == /cm/shared/sw/modules ]] ; then
  MODULEPATH=$MODULEPATH_DEFAULT
elif [[ :$MODULEPATH: != *:$MODULEPATH_DEFAULT:* ]] ; then
  MODULEPATH=$MODULEPATH:$MODULEPATH_DEFAULT
fi
unset MODULEPATH_DEFAULT
export MODULEPATH

if [[ $ENABLE_LMOD = 1 ]] ; then
  export LMOD_PACKAGE_PATH=@SITE@/site
  export LMOD_RC=@SITE@/lmodrc.lua
  export LMOD_SITE_MSG_FILE=@SITE@/site_msg.lua
  export LMOD_AVAIL_STYLE='system:<trim>:group'
  # TODO: working around configuration bug (remove when fixed):
  export LMOD_AVAIL_EXTENSIONS=no

  . @LMOD@/lmod/lmod/init/profile
  if [[ -z $__Init_Default_Modules ]]; then
    export __Init_Default_Modules=1
    # TODO: do we want to set defaults in another way?
    export LMOD_SYSTEM_DEFAULT_MODULES=${LMOD_SYSTEM_DEFAULT_MODULES:-slurm:openblas}
    module --initial_load restore
  else
    module refresh
  fi
else
  case "$0" in
      -bash|bash|*/bash) . /cm/local/apps/environment-modules/current/Modules/default/init/bash ;;
	 -ksh|ksh|*/ksh) . /cm/local/apps/environment-modules/current/Modules/default/init/ksh ;;
	 -zsh|zsh|*/zsh) . /cm/local/apps/environment-modules/current/Modules/default/init/zsh ;;
		      *) . /cm/local/apps/environment-modules/current/Modules/default/init/sh ;; # sh and default for scripts
  esac
fi
