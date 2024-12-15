{
  stdenv,
  pkg-config,
  which,
  pam,

  shared,
  aa_pkgs,
}:
let
  inherit (shared) apparmor-meta;
  inherit (aa_pkgs) libapparmor apparmor-src;
in
stdenv.mkDerivation {
  pname = "apparmor-pam";
  inherit (apparmor-src) version;
  src = apparmor-src;
  inherit (shared) doCheck;

  nativeBuildInputs = [
    pkg-config
    which
  ];

  buildInputs = [
    libapparmor
    pam
  ];

  postPatch = ''
    cd ./changehat/pam_apparmor
  '';
  makeFlags = [ "USE_SYSTEM=1" ];
  installFlags = [ "DESTDIR=$(out)" ];

  meta = apparmor-meta "PAM service";
}
