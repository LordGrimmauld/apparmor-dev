args@{
  lib,
  fetchpatch,
  stdenv,
  linuxHeaders ? stdenv.cc.libc.linuxHeaders,
  buildPackages,
  bashInteractive,
  python3,
  perl,
  coreutils,
  util-linux,
  strace,
  systemd,
  gnused,
  fetchFromGitLab,
}:
let
  apparmor_shared = import ./apparmor_shared.nix args;
  inherit (apparmor_shared) apparmor-meta python;
in
stdenv.mkDerivation {
  version = "4.1.0-unstable-2024-12-12";
  pname = "apparmor-src";

  src = fetchFromGitLab {
    owner = "apparmor";
    repo = "apparmor";
    rev = "6d7b5df94757b0d93d195f8789e3eb81bf0fdf4e";
    hash = "sha256-O+4a4qZQ1Xv/lNC3b91SsGHE6rD2XSMUUNABkk+vvoA=";
  };

  patches =
    [
      ./store-lib-path.patch
    ]
    ++ lib.optionals stdenv.hostPlatform.isMusl [
      (fetchpatch {
        url = "https://git.alpinelinux.org/aports/plain/testing/apparmor/0003-Added-missing-typedef-definitions-on-parser.patch?id=74b8427cc21f04e32030d047ae92caa618105b53";
        name = "0003-Added-missing-typedef-definitions-on-parser.patch";
        sha256 = "0yyaqz8jlmn1bm37arggprqz0njb4lhjni2d9c8qfqj0kll0bam0";
      })
    ];

  prePatch =
    ''
      chmod a+x ./common/list_capabilities.sh ./common/list_af_names.sh
      patchShebangs .
      substituteInPlace ./common/Make.rules \
        --replace-fail "/usr/bin/pod2man" "${buildPackages.perl}/bin/pod2man" \
        --replace-fail "/usr/bin/pod2html" "${buildPackages.perl}/bin/pod2html" \
        --replace-fail "/usr/share/man" "share/man"
      substituteInPlace ./utils/Makefile \
        --replace-fail "/usr/include/linux/capability.h" "${linuxHeaders}/include/linux/capability.h"
      substituteInPlace ./parser/tst/Makefile \
        --replace-fail "/usr/bin/prove" "${buildPackages.perl}/bin/prove"
      substituteInPlace ./parser/Makefile \
        --replace-fail "/usr/include/linux/capability.h" "${linuxHeaders}/include/linux/capability.h"
      substituteInPlace parser/rc.apparmor.functions \
        --replace-fail "/sbin/apparmor_parser" "$out/bin/apparmor_parser" # FIXME
      substituteInPlace ./libraries/libapparmor/swig/perl/Makefile.am \
        --replace-fail install_vendor install_site

      sed -i parser/rc.apparmor.functions -e '2i . ${./fix-rc.apparmor.functions.sh}'
      sed -i -E 's/^(DESTDIR|BINDIR|PYPREFIX)=.*//g' ./utils/Makefile
      sed -i utils/aa-unconfined -e "/my_env\['PATH'\]/d"
    ''
    + (lib.optionalString stdenv.hostPlatform.isMusl ''
      sed -i ./utils/Makefile -e "/\<vim\>/d"
    '');

  nativeBuildInputs = [
    python
    perl
    bashInteractive
  ];

  buildPhase = "# do nothing";

  installPhase = ''
    cp -r . "$out"
  '';

  meta = apparmor-meta "apparmor sources, with patches";
}
