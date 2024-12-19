{
  callPackage,
  lib,
  stdenv,
  withPerl ?
    stdenv.hostPlatform == stdenv.buildPlatform && lib.meta.availableOn stdenv.hostPlatform perl,
  perl,
  withPython ?
    stdenv.hostPlatform == stdenv.buildPlatform && lib.meta.availableOn stdenv.hostPlatform python3,
  python3,
}:
let
  apparmor-shared = rec {
    src = callPackage ./apparmor-sources.nix { inherit apparmor-shared; };

    version = src.version;

    apparmor-meta =
      component: with lib; {
        homepage = "https://apparmor.net/";
        description = "Mandatory access control system - ${component}";
        license = with licenses; [
          gpl2Only
          lgpl21Only
        ];
        maintainers = with maintainers; [
          grimmauld
        ];
        platforms = platforms.linux;
      };

    doCheck = withPerl && withPython;

    inherit withPerl withPython;

    python = python3.withPackages (ps: with ps; [ setuptools ]);

    aa-pkgs = {
      aa-teardown = callPackage ./components/aa-teardown.nix { };

      libapparmor = callPackage ./components/libapparmor.nix { inherit apparmor-shared; };
      apparmor-kernel-patches = callPackage ./components/apparmor-kernel-patches.nix {
        inherit apparmor-shared;
      };

      apparmor-parser = callPackage ./components/apparmor-parser.nix { inherit apparmor-shared; };
      apparmor-bin-utils = callPackage ./components/apparmor-bin-utils.nix { inherit apparmor-shared; };
      apparmor-pam = callPackage ./components/apparmor-pam.nix { inherit apparmor-shared; };

      apparmor-utils = callPackage ./components/apparmor-utils.nix { inherit apparmor-shared; };

      apparmor-profiles = callPackage ./components/apparmor-profiles.nix { inherit apparmor-shared; };

      apparmor-regression-test = callPackage ./check/regression-test-run.nix {
        inherit apparmor-shared;
      };
    };
  };
in
apparmor-shared.aa-pkgs
