{
  stdenv,
  pkg-config,
  which,
  pam,

  apparmor-shared,
}:
let
  inherit (apparmor-shared.aa-pkgs) libapparmor;
in
stdenv.mkDerivation {
  pname = "apparmor-pam";
  inherit (apparmor-shared) version src doCheck;

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

  meta = apparmor-shared.apparmor-meta "PAM service";
}
