{
  description = "Nix support for the AppArmor user space development project.";

  inputs = {
    nixpkgs.url = "github:LordGrimmauld/nixpkgs?ref=apparmor_module_pr";
    # nixpkgs.url = "git+file:/home/grimmauld/coding/nixpkgs";
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
        nixos-lib = import (nixpkgs + "/nixos/lib") { };
        inherit (pkgs) lib;
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
            apparmor-regression-test = nixos-lib.runTest {
              hostPkgs = pkgs.extend self.overlays.default;
              imports = lib.singleton {
                name = "appaarmor-regression-test-vm";
                nodes.test.security.apparmor.enable = true;
              };
              testScript = ''
                print("Starting VM test...")
                machine.wait_for_unit("default.target")
                machine.succeed("journalctl -u apparmor -b 0")
                machine.succeed("${lib.getExe check_pkgs.regression-test-run}")
              '';
            };
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
