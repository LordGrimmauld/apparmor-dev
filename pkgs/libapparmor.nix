args@{
  stdenv,
  lib,
  autoreconfHook,
  autoconf-archive,
  pkg-config,
  which,
  flex,
  bison,
  withPerl ?
    stdenv.hostPlatform == stdenv.buildPlatform && lib.meta.availableOn stdenv.hostPlatform perl,
  perl,
  withPython ?
    stdenv.hostPlatform == stdenv.buildPlatform && lib.meta.availableOn stdenv.hostPlatform python3,
  python3,
  swig,
  ncurses,
  libxcrypt,

  # test
  dejagnu,

  shared,
  flake_packages,
}:
let
  inherit (shared) python apparmor-meta;
  inherit (flake_packages) apparmor-src;
in
stdenv.mkDerivation {
  pname = "libapparmor-git";
  inherit (apparmor-src) version;
  src = apparmor-src;
  inherit (shared) doCheck;

  strictDeps = true;

  nativeBuildInputs = [
    autoconf-archive
    autoreconfHook
    bison
    flex
    pkg-config
    swig
    ncurses
    which
    perl
    dejagnu
  ] ++ lib.optional withPython python;

  buildInputs = [ libxcrypt ] ++ (lib.optional withPerl perl) ++ (lib.optional withPython python);

  # required to build apparmor-parser
  dontDisableStatic = true;

  postPatch = ''
    cd ./libraries/libapparmor
  '';

  # https://gitlab.com/apparmor/apparmor/issues/1
  configureFlags = [
    (lib.withFeature withPerl "perl")
    (lib.withFeature withPython "python")
  ];

  outputs = [ "out" ] ++ lib.optional withPython "python";

  postInstall = lib.optionalString withPython ''
    mkdir -p $python/lib
    mv $out/lib/python* $python/lib/
  '';

  checkInputs = [ dejagnu ];
  checkTarget = "check";

  meta = apparmor-meta "library";
}
