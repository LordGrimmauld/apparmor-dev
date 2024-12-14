{
  lib,
  writeShellScript,
  coreutils,
  gnused,
  gnugrep,
  flake_packages,
}:
let
  inherit (flake_packages) apparmor-parser;
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
