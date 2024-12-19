{
  description = "Nix support for the AppArmor user space development project.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
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
      gen_aa_pkgs = pkgs: {
        inherit (pkgs.callPackages ./pkgs { })
          libapparmor
          apparmor-utils
          apparmor-bin-utils
          apparmor-parser
          apparmor-pam
          apparmor-profiles
          apparmor-kernel-patches 
          apparmor-regression-test;
        };
    in
    (flake-utils.lib.eachSystem [ "aarch64-linux" "x86_64-linux" ] (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        nixos-lib = import (nixpkgs + "/nixos/lib") { };
        inherit (pkgs) lib;
        aa_pkgs = gen_aa_pkgs pkgs;
      in
      {
        packages = aa_pkgs;
        checks = aa_pkgs // {
          apparmor-nixpkgs-test = (pkgs.extend self.overlays.default).nixosTests.apparmor;
          apparmor-regression-test = nixos-lib.runTest {
            hostPkgs = pkgs.extend self.overlays.default;
            imports = lib.singleton {
              name = "appaarmor-regression-test-vm";
              nodes.test = {
                security.apparmor.enable = true;
                security.apparmor.enableCache = true; # e2e tess expects caches
                security.auditd.enable = true;
              };
            };
            testScript = ''
              print("Starting VM test...")
              machine.wait_for_unit("default.target")
              machine.succeed("journalctl -u apparmor -b 0")
              machine.succeed("${lib.getExe aa_pkgs.apparmor-regression-test}")
            '';
          };
        };
        lib = {
          apparmorRulesFromClosure = pkgs.callPackage ./nix/apparmorRulesFromClosure.nix { };
        };
        formatter = pkgs.nixfmt-rfc-style;
      }
    ))
    // {
      overlays.default = final: prev: (gen_aa_pkgs prev);

      githubActions = nix-github-actions.lib.mkGithubMatrix {
        checks = nixpkgs.lib.getAttrs [ "x86_64-linux" ] self.checks;
      }; # todo: figure out testing on aarch64-linux

      nixosModules.default = {
        nixpkgs.overlays = [ self.overlays.default ];
      };
    };
}
