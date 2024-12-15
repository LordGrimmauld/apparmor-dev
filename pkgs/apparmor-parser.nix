{
  stdenv,
  which,
  flex,

  # testing
  withPerl ?
    stdenv.hostPlatform == stdenv.buildPlatform && lib.meta.availableOn stdenv.hostPlatform perl,
  perl,
  withPython ?
    stdenv.hostPlatform == stdenv.buildPlatform && lib.meta.availableOn stdenv.hostPlatform python3,
  python3,
  bashInteractive,

  shared,
  bison,
  lib,
  flake_packages,
}:
let
  inherit (shared) apparmor-meta;
  inherit (flake_packages) libapparmor apparmor-src;
in
stdenv.mkDerivation {
  pname = "apparmor-parser";
  inherit (apparmor-src) version;
  src = apparmor-src;
  inherit (shared) doCheck;

  nativeBuildInputs = [
    bison
    flex
    which
  ];

  buildInputs = [ libapparmor ];

  postPatch = ''
    cd ./parser
  '';

  makeFlags = [
    "LANGS="
    "USE_SYSTEM=1"
    "INCLUDEDIR=${libapparmor}/include"
    "AR=${stdenv.cc.bintools.targetPrefix}ar"
  ];

  installFlags = [
    "DESTDIR=$(out)"
    "DISTRO=unknown"
  ];

  preCheck = "pushd ./tst";

  checkTarget = "tests";

  postCheck = "popd";

  checkInputs =
    [ bashInteractive ] ++ (lib.optional withPerl perl) ++ (lib.optional withPython python3);

  meta = (apparmor-meta "rule parser") // {
    mainProgram = "apparmor_parser";
  };
}
