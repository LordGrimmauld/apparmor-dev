{
  description = "Nix support for the AppArmor user space development project.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  # test_vm.nix

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    (flake-utils.lib.eachSystem [ "aarch64-linux" "x86_64-linux" ] (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        flake_packages = {
          aa-teardown = pkgs.callPackage ./nix/aa-teardown.nix { inherit flake_packages; };
          apparmor-src = pkgs.callPackage ./nix/apparmor-sources.nix { };
          apparmor-bin-utils = pkgs.callPackage ./nix/apparmor-bin-utils.nix { inherit flake_packages; };
          apparmor-kernel-patches = pkgs.callPackage ./nix/apparmor-kernel-patches.nix {
            inherit flake_packages;
          };
          apparmor-pam = pkgs.callPackage ./nix/apparmor-pam.nix { inherit flake_packages; };
          apparmor-parser = pkgs.callPackage ./nix/apparmor-parser.nix { inherit flake_packages; };
          apparmor-profiles = pkgs.callPackage ./nix/apparmor-profiles.nix { inherit flake_packages; };
          apparmor-utils = pkgs.callPackage ./nix/apparmor-utils.nix { inherit flake_packages; };
          libapparmor = pkgs.callPackage ./nix/libapparmor.nix { inherit flake_packages; };
          testing_config = pkgs.callPackage ./nix/testing_config.nix { inherit flake_packages; };
          regression-tests = pkgs.callPackage ./nix/regression-tests.nix { inherit flake_packages; };
          regression-test-runner = pkgs.callPackage ./nix/regression-test-runner.nix {
            inherit flake_packages;
          };
        };
      in
      {
        packages = flake_packages;
        checks = flake_packages // {
        };
        formatter = pkgs.nixfmt-rfc-style;
      }
    ))
    // {
    };
}
