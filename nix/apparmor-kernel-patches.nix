args@{
  stdenv,

  # shared
  lib,
  python3,

  flake_packages,
}:
let
  apparmor_shared = import ./apparmor_shared.nix args;
  inherit (apparmor_shared) apparmor-meta;
  inherit (flake_packages) apparmor-src;
in
stdenv.mkDerivation {
  pname = "apparmor-kernel-patches";
  inherit (apparmor-src) version;
  src = apparmor-src;
  inherit (apparmor_shared) doCheck;

  dontBuild = true;

  installPhase = ''
    mkdir "$out"
    cp -R ./kernel-patches/* "$out"
  '';

  meta = apparmor-meta "kernel patches";
}
