{
  stdenv,
  shared,
  flake_packages,
}:
let
  inherit (shared) apparmor-meta;
  inherit (flake_packages) apparmor-src;
in
stdenv.mkDerivation {
  pname = "apparmor-kernel-patches";
  inherit (apparmor-src) version;
  src = apparmor-src;
  inherit (shared) doCheck;

  dontBuild = true;

  installPhase = ''
    mkdir "$out"
    cp -R ./kernel-patches/* "$out"
  '';

  meta = apparmor-meta "kernel patches";
}
