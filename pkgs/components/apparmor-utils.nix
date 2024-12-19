{
  lib,
  makeWrapper,
  gawk,
  withPerl ? apparmor-shared.withPerl,
  perl,
  withPython ? apparmor-shared.withPython,
  bash,
  stdenv,
  which,
  linuxHeaders ? stdenv.cc.libc.linuxHeaders,

  apparmor-shared,
}:
let
  inherit (apparmor-shared) python;
  inherit (apparmor-shared.aa-pkgs) aa-teardown libapparmor apparmor-parser;
in
python.pkgs.buildPythonApplication {
  pname = "apparmor-utils";
  inherit (apparmor-shared) version src doCheck;
  format = "other";

  prePatch =
    ''
      substituteInPlace utils/aa-remove-unknown \
        --replace-fail "/lib/apparmor/rc.apparmor.functions" "${apparmor-parser}/lib/apparmor/rc.apparmor.functions"
      substituteInPlace ./utils/Makefile \
        --replace-fail "/usr/include/linux/capability.h" "${linuxHeaders}/include/linux/capability.h"
      sed -i -E 's/^(DESTDIR|BINDIR|PYPREFIX)=.*//g' ./utils/Makefile
      sed -i utils/aa-unconfined -e "/my_env\['PATH'\]/d"
    ''
    + (lib.optionalString stdenv.hostPlatform.isMusl ''
      sed -i ./utils/Makefile -e "/\<vim\>/d"
    '');

  strictDeps = true;

  nativeBuildInputs = [
    makeWrapper
    which
    python
  ];

  buildInputs = [
    bash
    perl
    python
    libapparmor
    (libapparmor.python or null)
  ];

  checkTarget = "check";

  propagatedBuildInputs = [
    (libapparmor.python or null)

    # Used by aa-notify
    python.pkgs.notify2
    python.pkgs.psutil
  ];

  postPatch = "cd ./utils";

  makeFlags = [ "LANGS=" ];

  installFlags = [
    "DESTDIR=$(out)"
    "BINDIR=$(out)/bin"
    "VIM_INSTALL_PATH=$(out)/share"
    "PYPREFIX="
  ];

  postInstall = ''
    wrapProgram $out/bin/aa-remove-unknown \
     --prefix PATH : ${lib.makeBinPath [ gawk ]}

    ln -s ${aa-teardown} $out/bin/aa-teardown
  '';

  meta = apparmor-shared.apparmor-meta "user-land utilities" // {
    broken = !(withPython && withPerl);
  };
}
