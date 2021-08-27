library(IRkernel)
installspec <- IRkernel::installspec
env <- new.env(parent = environment(installspec))
environment(installspec) <- env
# overwrite write to fix permissions first
write <- function(x, file) {
  system2('chmod', c('+w',file))
  cat(x, file = file, append = FALSE)
}
assign("write", write, env)
installspec(prefix=Sys.getenv('out'))
