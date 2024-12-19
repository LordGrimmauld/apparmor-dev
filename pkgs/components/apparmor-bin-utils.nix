{
  stdenv,
  pkg-config,
  which,
  lib,

  # testing
  withPerl ? apparmor-shared.withPerl,
  perl,

  apparmor-shared,
}:
let
  inherit (apparmor-shared.aa-pkgs) libapparmor;
in
stdenv.mkDerivation {
  pname = "apparmor-bin-utils";
  inherit (apparmor-shared) version src doCheck;

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

  meta = apparmor-shared.apparmor-meta "binary user-land utilities";
}
