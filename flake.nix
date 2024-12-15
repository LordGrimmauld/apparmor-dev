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

  outputs =
    {
      self,
      nixpkgs,
      nix-github-actions,
      flake-utils,
    }:
    let
      gen_shared = pkgs: import ./nix/aa-shared.nix { inherit (pkgs) python3 lib; };
      gen_aa_pkgs =
        pkgs:
        let
          shared = gen_shared pkgs;
          aa_pkgs = with pkgs; {
            apparmor-src = callPackage ./pkgs/apparmor-sources.nix { inherit shared; }; # support
            aa-teardown = callPackage ./pkgs/aa-teardown.nix { inherit aa_pkgs; }; # support
            apparmor-bin-utils = callPackage ./pkgs/apparmor-bin-utils.nix { inherit aa_pkgs shared; };
            apparmor-kernel-patches = callPackage ./pkgs/apparmor-kernel-patches.nix {
              inherit aa_pkgs shared;
            };
            apparmor-pam = callPackage ./pkgs/apparmor-pam.nix { inherit aa_pkgs shared; };
            apparmor-parser = callPackage ./pkgs/apparmor-parser.nix { inherit aa_pkgs shared; };
            apparmor-profiles = callPackage ./pkgs/apparmor-profiles.nix { inherit aa_pkgs shared; };
            apparmor-utils = callPackage ./pkgs/apparmor-utils.nix { inherit aa_pkgs shared; };
            libapparmor = callPackage ./pkgs/libapparmor.nix { inherit aa_pkgs shared; };
          };
        in
        aa_pkgs;
    in
    (flake-utils.lib.eachSystem [ "aarch64-linux" "x86_64-linux" ] (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        shared = gen_shared pkgs;
        aa_pkgs = gen_aa_pkgs pkgs;
        check_pkgs = {
          regression-test-src = pkgs.callPackage ./check/regression-test-src.nix {
            inherit aa_pkgs shared;
          }; # check
          regression-test-run = pkgs.callPackage ./check/regression-test-run.nix {
            # check
            inherit aa_pkgs check_pkgs;
          };
        };
      in
      {
        packages = aa_pkgs;
        checks =
          aa_pkgs
          // check_pkgs
          // {
            apparmor-nixpkgs-test = (pkgs.extend self.overlays.default).nixosTests.apparmor;
          };
        lib = {
          apparmorRulesFromClosure = pkgs.callPackage ./nix/apparmorRulesFromClosure.nix { };
        };
        formatter = pkgs.nixfmt-rfc-style;
      }
    ))
    // rec {
      overlays = {
        default = final: prev: (gen_aa_pkgs prev);
      };

      githubActions = nix-github-actions.lib.mkGithubMatrix {
        checks = nixpkgs.lib.getAttrs [ "x86_64-linux" ] self.checks;
      }; # todo: figure out testing on aarch64-linux

      nixosModules = {
        # Use a locally built Lix
        default = {
          nixpkgs.overlays = [ overlays.default ];
        };
      };
    };
}
