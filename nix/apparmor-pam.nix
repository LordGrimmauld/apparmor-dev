args@{
  stdenv,
  pkg-config,
  which,
  pam,

  # shared
  lib,
  python3,

  flake_packages,
}:
let
  apparmor_shared = import ./apparmor_shared.nix args;
  inherit (apparmor_shared) apparmor-meta;
  inherit (flake_packages) libapparmor apparmor-src;
in
stdenv.mkDerivation {
  pname = "apparmor-pam";
  inherit (apparmor-src) version;
  src = apparmor-src;
  inherit (apparmor_shared) doCheck;

  nativeBuildInputs = [
    pkg-config
    which
  ];

  buildInputs = [
    libapparmor
    pam
  ];

  postPatch = ''
    cd ./changehat/pam_apparmor
  '';
  makeFlags = [ "USE_SYSTEM=1" ];
  installFlags = [ "DESTDIR=$(out)" ];

  meta = apparmor-meta "PAM service";
}
