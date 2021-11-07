if (! ${?ENABLE_LMOD} ) then
  setenv ENABLE_LMOD 1
endif

if ( $ENABLE_LMOD == 1 ) then
  set MODULEPATH_DEFAULT=@MODS@/Core
else
  set MODULEPATH_DEFAULT=/cm/shared/sw/modules
endif

if ( ! $?MODULEPATH || $MODULEPATH == /cm/shared/sw/modules ) then
  setenv MODULEPATH $MODULEPATH_DEFAULT
else if ( ":${MODULEPATH}:" !~ *":${MODULEPATH_DEFAULT}:"* ) then
  setenv MODULEPATH $MODULEPATH:$MODULEPATH_DEFAULT
endif
unset MODULEPATH_DEFAULT

if ( $ENABLE_LMOD == 1 ) then
  setenv LMOD_PACKAGE_PATH @SITE@/site
  setenv LMOD_RC @SITE@/lmodrc.lua
  setenv LMOD_SITE_MSG_FILE @SITE@/site_msg.lua
  setenv LMOD_AVAIL_STYLE 'system:<trim>:group'
  setenv LMOD_AVAIL_EXTENSIONS no

  source @LMOD@/lmod/lmod/init/cshrc

  if ( ! $?__Init_Default_Modules ) then
    setenv __Init_Default_Modules 1
    setenv LMOD_SYSTEM_DEFAULT_MODULES slurm:openblas
    module --initial_load restore
  else
    module refresh
  endif
else
  if ($?tcsh) then
    source /cm/local/apps/environment-modules/current/Modules/default/init/tcsh
  else
    source /cm/local/apps/environment-modules/current/Modules/default/init/csh
  endif
endif
