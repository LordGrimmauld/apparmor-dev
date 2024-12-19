{
  stdenv,
  which,
  flex,
  linuxHeaders ? stdenv.cc.libc.linuxHeaders,

  # testing
  withPerl ? apparmor-shared.withPerl,
  perl,
  withPython ? apparmor-shared.withPython,
  bashInteractive,

  apparmor-shared,
  bison,
  lib,
}:
let
  inherit (apparmor-shared) python;
  inherit (apparmor-shared.aa-pkgs) libapparmor;
in
stdenv.mkDerivation {
  pname = "apparmor-parser";
  inherit (apparmor-shared) version src doCheck;

  prePatch = ''
    substituteInPlace ./parser/tst/Makefile \
      --replace-fail "/usr/bin/prove" "${perl}/bin/prove"
    substituteInPlace ./parser/Makefile \
      --replace-fail "/usr/include/linux/capability.h" "${linuxHeaders}/include/linux/capability.h"
    substituteInPlace parser/rc.apparmor.functions \
      --replace-fail "/sbin/apparmor_parser" "$out/bin/apparmor_parser" # FIXME
    sed -i parser/rc.apparmor.functions -e '2i . ${../patches/fix-rc.apparmor.functions.sh}'
  '';

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
    [ bashInteractive ] ++ (lib.optional withPerl perl) ++ (lib.optional withPython python);

  meta = (apparmor-shared.apparmor-meta "rule parser") // {
    mainProgram = "apparmor_parser";
  };
}
