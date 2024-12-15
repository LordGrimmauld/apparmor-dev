{
  lib,
  writeShellScript,
  coreutils,
  gnused,
  gnugrep,
  aa_pkgs,
}:
let
  inherit (aa_pkgs) apparmor-parser;
in
writeShellScript "aa-teardown" ''
  PATH="${
    lib.makeBinPath [
      coreutils
      gnused
      gnugrep
    ]
  }:$PATH"
  . ${apparmor-parser}/lib/apparmor/rc.apparmor.functions
  remove_profiles
''
