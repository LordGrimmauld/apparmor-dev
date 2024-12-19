{
  stdenv,
  lib,
  autoreconfHook,
  autoconf-archive,
  pkg-config,
  which,
  flex,
  bison,
  withPerl ? apparmor-shared.withPerl,
  perl,
  withPython ? apparmor-shared.withPython,
  swig,
  ncurses,
  libxcrypt,

  # test
  dejagnu,

  apparmor-shared,
}:
let
  inherit (apparmor-shared) python;
in
stdenv.mkDerivation {
  pname = "libapparmor-git";
  inherit (apparmor-shared) src version doCheck;

  prePatch = ''
    substituteInPlace ./libraries/libapparmor/swig/perl/Makefile.am \
      --replace-fail install_vendor install_site
  '';

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

  meta = apparmor-shared.apparmor-meta "library";
}
