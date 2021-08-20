{ pkgs
}:

# Bootstrap a new stdenv that includes our nss_sss in glibc

let
  glibc = pkgs.glibc.overrideDerivation (old: {
    postInstall = old.postInstall + ''
      ln -s ${pkgs.nss_sss}/lib/*.so.* $out/lib
    '';
  });
  binutils = pkgs.binutils.override {
    libc = glibc;
  };
  gcc = pkgs.gcc.override {
    bintools = binutils;
    libc = glibc;
  };
in

pkgs.stdenv.override {
  cc = gcc;
  overrides = self: super: {
    inherit glibc binutils gcc;
  };
  allowedRequisites = pkgs.stdenv.allowedRequisites ++
    [ glibc.out glibc.dev glibc.bin binutils pkgs.nss_sss ];
}
