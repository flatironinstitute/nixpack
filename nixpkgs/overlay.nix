self: pkgs:
with pkgs;

{
  nss_sss = callPackage sssd/nss-client.nix { };

  libuv = libuv.overrideAttrs (old: {
    doCheck = false; # failure
  });

  nix = (nix.override {
    withLibseccomp = false;
    withAWS = false;
  }).overrideAttrs (old: {
    doInstallCheck = false;
  });
}
