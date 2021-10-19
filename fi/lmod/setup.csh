set MODULEPATH_DEFAULT=@MODS@/Core
setenv LMOD_PACKAGE_PATH @SITE@/site
setenv LMOD_RC @SITE@/lmodrc.lua
setenv LMOD_SITE_MSG_FILE @SITE@/site_msg.lua
setenv LMOD_AVAIL_STYLE 'system:<trim>:group'
setenv LMOD_AVAIL_EXTENSIONS no

if ( ! $?MODULEPATH || $MODULEPATH == /cm/shared/sw/modules ) then
  setenv MODULEPATH $MODULEPATH_DEFAULT
else if ( ":${MODULEPATH}:" !~ *":${MODULEPATH_DEFAULT}:"* ) then
  setenv MODULEPATH $MODULEPATH:$MODULEPATH_DEFAULT
endif
unset MODULEPATH_DEFAULT

source @LMOD@/lmod/lmod/init/cshrc
if ( ! $?__Init_Default_Modules ) then
  setenv __Init_Default_Modules 1
  setenv LMOD_SYSTEM_DEFAULT_MODULES slurm:openblas
  module --initial_load restore
else
  module refresh
endif
