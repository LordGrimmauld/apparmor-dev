{
  lib,
  closureInfo,
  runCommandLocal,
}:

let
  # Generate generic AppArmor rules in a file, from the closure of given
  # rootPaths. To be included in an AppArmor profile like so:
  #
  #   include "${apparmorRulesFromClosure { } [ pkgs.hello ]}"
  #
  # built local because caching makes no sense for all the different profiles.
  apparmorRulesFromClosure =
    {
      # The store path of the derivation is given in $path
      additionalRules ? [ ],
      # TODO: factorize here some other common paths
      # that may emerge from use cases.
      baseRules ? [
        "r $path"
        "r $path/etc/**"
        "mr $path/share/**"
        # Note that not all libraries are prefixed with "lib",
        # eg. glibc-2.30/lib/ld-2.30.so
        "mr $path/lib/**.so*"
        "mr $path/lib64/**.so*"
        # eg. glibc-2.30/lib/gconv/gconv-modules
        "r $path/lib/**"
        "r $path/lib64/**"
        # Internal executables
        "ixr $path/libexec/**"
      ],
      name ? "",
    }:
    rootPaths:
    runCommandLocal ("apparmor-closure-rules" + lib.optionalString (name != "") "-${name}") { } ''
      touch $out
      while read -r path
      do printf >>$out "%s,\n" ${
        lib.concatMapStringsSep " " (x: "\"${x}\"") (baseRules ++ additionalRules)
      }
      done <${closureInfo { inherit rootPaths; }}/store-paths
    '';
in
{
  inherit apparmorRulesFromClosure;
}
