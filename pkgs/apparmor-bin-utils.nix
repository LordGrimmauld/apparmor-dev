{
  stdenv,
  pkg-config,
  which,
  lib,

  # testing
  withPerl ?
    stdenv.hostPlatform == stdenv.buildPlatform && lib.meta.availableOn stdenv.hostPlatform perl,
  perl,

  shared,

  flake_packages,
}:
let
  inherit (shared) apparmor-meta;
  inherit (flake_packages) libapparmor apparmor-src;
in
stdenv.mkDerivation {
  pname = "apparmor-bin-utils";
  inherit (apparmor-src) version;
  src = apparmor-src;
  inherit (shared) doCheck;

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
