{
  stdenv,
  which,

  apparmor-shared,
  callPackage,
}:
let
  inherit (apparmor-shared.aa-pkgs) apparmor-utils apparmor-parser;
in
stdenv.mkDerivation {
  pname = "apparmor-profiles";
  inherit (apparmor-shared) version src doCheck;

  nativeBuildInputs = [ which ];

  postPatch = ''
    cd ./profiles
  '';

  installFlags = [
    "DESTDIR=$(out)"
    "EXTRAS_DEST=$(out)/share/apparmor/extra-profiles"
  ];

  checkTarget = "check";

  checkInputs = [
    apparmor-parser
    apparmor-utils
  ];

  preCheck = ''
    export USE_SYSTEM=1
    export LOGPROF="aa-logprof --configdir ${
      callPackage ../check/testing_config.nix { inherit apparmor-shared; }
    } --no-check-mountpoint"
  '';

  meta = apparmor-shared.apparmor-meta "profiles";
}
