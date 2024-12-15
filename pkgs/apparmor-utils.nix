{
  stdenv,
  lib,
  makeWrapper,
  gawk,
  withPerl ?
    stdenv.hostPlatform == stdenv.buildPlatform && lib.meta.availableOn stdenv.hostPlatform perl,
  perl,
  withPython ?
    stdenv.hostPlatform == stdenv.buildPlatform && lib.meta.availableOn stdenv.hostPlatform python3,
  python3,
  bash,
  which,

  shared,
  aa_pkgs,
}:
let
  inherit (shared) python apparmor-meta;
  inherit (aa_pkgs)
    libapparmor
    apparmor-parser
    aa-teardown
    apparmor-src
    ;
in
python.pkgs.buildPythonApplication {
  pname = "apparmor-utils";
  inherit (apparmor-src) version;
  src = apparmor-src;
  inherit (shared) doCheck;
  format = "other";

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

  prePatch = ''
    substituteInPlace utils/aa-remove-unknown \
      --replace "/lib/apparmor/rc.apparmor.functions" "${apparmor-parser}/lib/apparmor/rc.apparmor.functions"
  '';

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

  meta = apparmor-meta "user-land utilities" // {
    broken = !(withPython && withPerl);
  };
}
