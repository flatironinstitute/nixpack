self: pkgs:
with pkgs;

{
  nss_sss = callPackage sssd/nss-client.nix { };

  libuv = libuv.overrideAttrs (old: {
    doCheck = false; # failure
  });

  nix = (nix.override {
    withAWS = false;
  }).overrideAttrs (old: {
    patches = [../patch/nix-ignore-fsea.patch];
    doInstallCheck = false;
  });
}
