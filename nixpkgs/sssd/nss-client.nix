{ stdenv
, fetchFromGitHub
, autoreconfHook
, pkg-config
, glibc, pam, openldap, libkrb5, dnsutils, cyrus_sasl, nss
, popt, talloc, tdb, tevent, ldb, ding-libs, pcre2, c-ares
, glib, dbus
, jansson, libunistring, openssl, p11-kit
}:

let
  version = "2.9.4";
in

stdenv.mkDerivation rec {
  name = "sssd-nss-client-${version}";

  src = fetchFromGitHub {
    owner = "SSSD";
    repo = "sssd";
    rev = "refs/tags/${version}";
    hash = "sha256-VJXZndbmC6mAVxzvv5Wjb4adrQkP16Rt4cgjl4qGDIc=";
  };

  # libnss_sss.so does not in fact use any of these -- they're just needed for configure
  nativeBuildInputs = [ autoreconfHook pkg-config
    pam openldap libkrb5 dnsutils cyrus_sasl nss
    popt tdb tevent ldb ding-libs pcre2 c-ares
    glib dbus
    jansson p11-kit
  ];
  buildInputs = [
    talloc
    openssl libunistring 
  ];

  preConfigure = ''
    configureFlagsArray=(
      --prefix=$out
      --localstatedir=/var
      --sysconfdir=/etc
      --with-os=redhat
      --with-nscd=${glibc.bin}/sbin/nscd
      --with-ldb-lib-dir=$out/modules/ldb
      --disable-cifs-idmap-plugin
      --without-autofs
      --without-kcm
      --without-libnl
      --without-libwbclient
      --without-manpages
      --without-nfsv4-idmapd-plugin
      --without-python2-bindings
      --without-python3-bindings
      --without-samba
      --without-secrets
      --without-selinux
      --without-semanage
      --without-ssh
      --without-sudo
      --without-oidc-child
    )
  '';

  enableParallelBuilding = true;

  buildFlags = [ "libnss_sss.la" ];
  installTargets = [ "install-nsslibLTLIBRARIES" ];

}
