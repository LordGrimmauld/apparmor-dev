{
  description = "Nix support for the AppArmor user space development project.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    nix-github-actions = {
      url = "github:nix-community/nix-github-actions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # test_vm.nix

  outputs =
    {
      self,
      nixpkgs,
      nix-github-actions,
      flake-utils,
    }:
    (flake-utils.lib.eachSystem [ "aarch64-linux" "x86_64-linux" ] (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        shared = import ./nix/aa-shared.nix { inherit (pkgs) python3 lib; };
        flake_packages = with pkgs; {
          aa-teardown = callPackage ./pkgs/aa-teardown.nix { inherit flake_packages; }; # support
          apparmor-src = callPackage ./pkgs/apparmor-sources.nix { inherit shared; }; # support
          apparmor-bin-utils = callPackage ./pkgs/apparmor-bin-utils.nix { inherit flake_packages shared; };
          apparmor-kernel-patches = callPackage ./pkgs/apparmor-kernel-patches.nix {
            inherit flake_packages shared;
          };
          apparmor-pam = callPackage ./pkgs/apparmor-pam.nix { inherit flake_packages shared; };
          apparmor-parser = callPackage ./pkgs/apparmor-parser.nix { inherit flake_packages shared; };
          apparmor-profiles = callPackage ./pkgs/apparmor-profiles.nix { inherit flake_packages shared; };
          apparmor-utils = callPackage ./pkgs/apparmor-utils.nix { inherit flake_packages shared; };
          libapparmor = callPackage ./pkgs/libapparmor.nix { inherit flake_packages shared; };
          testing_config = callPackage ./pkgs/testing_config.nix { inherit flake_packages; }; # support
          regression-test-src = callPackage ./check/regression-test-src.nix {
            inherit flake_packages shared;
          }; # check
          regression-test-run = callPackage ./check/regression-test-run.nix {
            # check
            inherit flake_packages;
          };
        };
      in
      {
        packages = flake_packages;
        checks = flake_packages;
        lib = {
          apparmorRulesFromClosure = pkgs.callPackage ./nix/apparmorRulesFromClosure.nix { };
        };
        formatter = pkgs.nixfmt-rfc-style;
      }
    ))
    // {
      githubActions = nix-github-actions.lib.mkGithubMatrix {
        checks = nixpkgs.lib.getAttrs [ "x86_64-linux" ] self.checks;
      }; # todo: figure out testing on aarch64-linux
    };
}
