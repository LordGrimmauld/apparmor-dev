args@{
  stdenv,
  which,

  # shared
  lib,
  python3,

  # outputs
  flake_packages,
}:
let
  apparmor_shared = import ./apparmor_shared.nix args;
  inherit (apparmor_shared) apparmor-meta;
  inherit (flake_packages)
    testing_config
    apparmor-utils
    apparmor-parser
    apparmor-src
    ;
in
stdenv.mkDerivation {
  pname = "apparmor-profiles";
  inherit (apparmor-src) version;
  src = apparmor-src;
  inherit (apparmor_shared) doCheck;

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
    export LOGPROF="aa-logprof --configdir ${testing_config} --no-check-mountpoint"
  '';

  meta = apparmor-meta "profiles";
}
