{
  lib,
  writeShellScript,
  coreutils,
  gnused,
  gnugrep,
  apparmor-parser,
}:
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
