{
  stdenv,
  apparmor-shared,
}:
stdenv.mkDerivation {
  pname = "apparmor-kernel-patches";
  inherit (apparmor-shared) version src doCheck;

  dontBuild = true;

  installPhase = ''
    mkdir "$out"
    cp -R ./kernel-patches/* "$out"
  '';

  meta = apparmor-shared.apparmor-meta "kernel patches";
}
