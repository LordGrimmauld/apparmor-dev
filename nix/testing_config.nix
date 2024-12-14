{
  runCommand,
  util-linux,
  glibc,
  runtimeShell,
  bashInteractive,

  flake_packages,
}:
let

  inherit (flake_packages) apparmor-parser apparmor-src;
in
(runCommand "logprof_conf"
  {
    header = ''
      [settings]
        # /etc/apparmor.d/ is read-only on NixOS
        profiledir = /var/cache/apparmor/logprof
        inactive_profiledir = /etc/apparmor.d/disable
        # Use: journalctl -b --since today --grep audit: | aa-logprof
        logfiles = /dev/stdin

        parser = ${apparmor-parser}/bin/apparmor_parser
        ldd = ${glibc.bin}/bin/ldd
        logger = ${util-linux}/bin/logger

        # customize how file ownership permissions are presented
        # 0 - off
        # 1 - default of what ever mode the log reported
        # 2 - force the new permissions to be user
        # 3 - force all perms on the rule to be user
        default_owner_prompt = 1

      [qualifiers]
        ${runtimeShell} = icnu
        ${bashInteractive}/bin/sh = icnu
        ${bashInteractive}/bin/bash = icnu
    '';
    passAsFile = [ "header" ];
  }
  ''
    mkdir $out
    cp $headerPath $out/logprof.conf
    cp ${apparmor-src}/utils/severity.db $out/severity.db
    sed '1,/\[qualifiers\]/d' ${apparmor-src}/utils/logprof.conf >> $out/logprof.conf
  ''
)
