args@{
  stdenv,
  pkg-config,
  which,
  lib,

  # testing
  withPerl ?
    stdenv.hostPlatform == stdenv.buildPlatform && lib.meta.availableOn stdenv.hostPlatform perl,
  perl,

  # shared
  python3,

  flake_packages,
}:
let
  apparmor_shared = import ./apparmor_shared.nix args;
  inherit (apparmor_shared) apparmor-meta;
  inherit (flake_packages) libapparmor apparmor-src;
in
stdenv.mkDerivation {
  pname = "apparmor-bin-utils";
  inherit (apparmor-src) version;
  src = apparmor-src;
  inherit (apparmor_shared) doCheck;

  nativeBuildInputs = [
    pkg-config
    libapparmor
    which
  ];

  buildInputs = [
    libapparmor
  ];

  checkInputs = lib.optional withPerl perl;

  postPatch = ''
    cd ./binutils
  '';

  makeFlags = [
    "LANGS="
    "USE_SYSTEM=1"
  ];

  installFlags = [
    "DESTDIR=$(out)"
    "BINDIR=$(out)/bin"
    "SBINDIR=$(out)/bin"
  ];

  meta = apparmor-meta "binary user-land utilities";
}
