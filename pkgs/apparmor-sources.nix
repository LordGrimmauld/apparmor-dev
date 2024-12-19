{
  lib,
  fetchpatch,
  stdenv,
  buildPackages,
  bashInteractive,
  fetchFromGitLab,
  apparmor-shared,
  withPython ? apparmor-shared.withPython,
  withPerl ? apparmor-shared.withPerl,
  perl,
}:
let
  inherit (apparmor-shared) python;
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
      ./patches/store-lib-path.patch
    ]
    ++ lib.optionals stdenv.hostPlatform.isMusl [
      (fetchpatch {
        url = "https://git.alpinelinux.org/aports/plain/testing/apparmor/0003-Added-missing-typedef-definitions-on-parser.patch?id=74b8427cc21f04e32030d047ae92caa618105b53";
        name = "0003-Added-missing-typedef-definitions-on-parser.patch";
        sha256 = "0yyaqz8jlmn1bm37arggprqz0njb4lhjni2d9c8qfqj0kll0bam0";
      })
    ];

  prePatch = ''
    chmod a+x ./common/list_capabilities.sh ./common/list_af_names.sh
    patchShebangs .
    substituteInPlace ./common/Make.rules \
      --replace-fail "/usr/bin/pod2man" "${buildPackages.perl}/bin/pod2man" \
      --replace-fail "/usr/bin/pod2html" "${buildPackages.perl}/bin/pod2html" \
      --replace-fail "/usr/share/man" "share/man"
  '';

  nativeBuildInputs =
    [
      bashInteractive
    ]
    ++ (lib.optional withPython python)
    ++ (lib.optional withPerl perl);

  buildPhase = "# do nothing";

  installPhase = ''
    cp -r . "$out"
  '';

  meta = apparmor-shared.apparmor-meta "apparmor sources, with patches";
}
