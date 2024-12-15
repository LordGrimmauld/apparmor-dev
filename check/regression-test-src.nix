{
  stdenv,
  pkg-config,
  lib,

  # testing
  withPerl ?
    stdenv.hostPlatform == stdenv.buildPlatform && lib.meta.availableOn stdenv.hostPlatform perl,
  perl,
  attr,
  dbus,
  liburing,

  flake_packages,
  shared,

  util-linux,
  coreutils,
  gnused,
  strace,
  systemd,
}:
let
  inherit (shared) apparmor-meta;
  inherit (flake_packages)
    libapparmor
    apparmor-src
    apparmor-parser
    apparmor-bin-utils
    ;
in
stdenv.mkDerivation {
  pname = "apparmor-regression-tests";
  inherit (apparmor-src) version;
  src = apparmor-src;
  inherit (shared) doCheck;

  prePatch = ''
    sed -i "s@/sbin/apparmor_parser@${apparmor-parser}/bin/apparmor_parser@g" tests/regression/apparmor/*.inc*
    sed -i "s@/sbin/apparmor_parser@${apparmor-parser}/bin/apparmor_parser@g" tests/regression/apparmor/netdomain/lib/netdomain_init.exp

    substituteInPlace ./tests/regression/apparmor/prologue.inc \
      --replace-fail "/bin/true" "${lib.getExe' coreutils "true"}"
    substituteInPlace ./tests/regression/apparmor/regex.sh \
      --replace-fail "/bin/true" "${lib.getExe' coreutils "true"}"
    substituteInPlace ./tests/regression/apparmor/regex.sh \
      --replace-fail "/bin/false" "${lib.getExe' coreutils "false"}"
    substituteInPlace ./tests/regression/apparmor/exec.sh \
      --replace-fail "/bin/true" "${lib.getExe' coreutils "true"}"
    substituteInPlace ./tests/regression/apparmor/AppArmor.rtf \
      --replace-fail "/bin/true" "${lib.getExe' coreutils "true"}"
    substituteInPlace ./tests/regression/apparmor/ptrace.sh \
      --replace-fail "/bin/true" "${lib.getExe' coreutils "true"}"

    substituteInPlace ./tests/regression/apparmor/mkdir.sh \
      --replace-fail "/bin/rmdir" "${lib.getExe' coreutils "rmdir"}"
    substituteInPlace ./tests/regression/apparmor/mkdir.sh \
      --replace-fail "/bin/mkdir" "${lib.getExe' coreutils "mkdir"}"
    substituteInPlace ./tests/regression/apparmor/swap.sh \
      --replace-fail "/bin/mkdir" "${lib.getExe' coreutils "mkdir"}"
    substituteInPlace ./tests/regression/apparmor/mount.sh \
      --replace-fail "/bin/mkdir" "${lib.getExe' coreutils "mkdir"}"
    substituteInPlace ./tests/regression/apparmor/pivot_root.sh \
      --replace-fail "/bin/mkdir" "${lib.getExe' coreutils "mkdir"}"
      
    substituteInPlace ./tests/regression/apparmor/netdomain/lib/netdomain_init.exp \
      --replace-fail "/usr/bin/whoami" "${lib.getExe' coreutils "whoami"}"
    substituteInPlace ./tests/regression/apparmor/netdomain/lib/netdomain_init.exp \
      --replace-fail "/bin/sed" "${lib.getExe gnused}"
      
    substituteInPlace ./tests/regression/apparmor/swap.sh \
      --replace-fail "/sbin/mkswap" "${lib.getExe' util-linux "mkswap"}"
    substituteInPlace ./tests/regression/apparmor/swap.sh \
      --replace-fail "/sbin/swapoff" "${lib.getExe' util-linux "swapoff"}"
    substituteInPlace ./tests/regression/apparmor/swap.sh \
      --replace-fail "/sbin/swapon" "${lib.getExe' util-linux "swapon"}"

    substituteInPlace ./tests/regression/apparmor/strace.sh \
      --replace-fail "/usr/bin/strace" "${lib.getExe strace}"

    substituteInPlace ./tests/regression/apparmor/mount.inc \
      --replace-fail "/bin/findmnt" "${lib.getExe' util-linux "findmnt"}"
    substituteInPlace ./tests/regression/apparmor/environ.sh \
      --replace-fail "/bin/findmnt" "${lib.getExe' util-linux "findmnt"}"

    substituteInPlace ./tests/regression/apparmor/mount.sh \
      --replace-fail "/sbin/mkfs" "${lib.getExe' util-linux "mkfs"}"
    substituteInPlace ./tests/regression/apparmor/swap.sh \
      --replace-fail "/sbin/mkfs" "${lib.getExe' util-linux "mkfs"}"
    substituteInPlace ./tests/regression/apparmor/attach_disconnected.sh \
      --replace-fail "/sbin/mkfs" "${lib.getExe' util-linux "mkfs"}"
    substituteInPlace ./tests/regression/apparmor/pivot_root.sh \
      --replace-fail "/sbin/mkfs" "${lib.getExe' util-linux "mkfs"}"
      
    substituteInPlace ./tests/regression/apparmor/pivot_root.sh \
      --replace-fail "/bin/mount" "${lib.getExe' util-linux "mount"}"
    substituteInPlace ./tests/regression/apparmor/mount.sh \
      --replace-fail "/bin/mount" "${lib.getExe' util-linux "mount"}"
    substituteInPlace ./tests/regression/apparmor/mount.sh \
      --replace-fail "/bin/umount" "${lib.getExe' util-linux "umount"}"
    substituteInPlace ./tests/regression/apparmor/swap.sh \
      --replace-fail "/bin/mount" "${lib.getExe' util-linux "mount"}"
    substituteInPlace ./tests/regression/apparmor/swap.sh \
      --replace-fail "/bin/umount" "${lib.getExe' util-linux "umount"}"

    substituteInPlace ./tests/regression/apparmor/swap.sh \
      --replace-fail "/sbin/losetup" "${lib.getExe' util-linux "losetup"}"
    substituteInPlace ./tests/regression/apparmor/mount.sh \
      --replace-fail "/sbin/losetup" "${lib.getExe' util-linux "losetup"}"
    substituteInPlace ./tests/regression/apparmor/pivot_root.sh \
      --replace-fail "/sbin/init" "${lib.getExe' systemd "init"}"

    substituteInPlace ./tests/regression/apparmor/deleted.sh \
      --replace-fail "unix:create" "unix:"
    substituteInPlace ./tests/regression/apparmor/attach_disconnected.sh \
      --replace-fail "unix:create" "unix:"
    substituteInPlace ./tests/regression/apparmor/unix_fd_server.sh \
      --replace-fail "unix:create" "unix:"

    sed -i "s@genprofile \(.*\)@genprofile \\1 \"/nix/store/*/lib/*.so*:rm\"@g" tests/regression/apparmor/sd_flags.sh
    sed -i "s@genprofile \(.*\)@genprofile \\1 \"/nix/store/*/lib/*.so*:rm\"@g" tests/regression/apparmor/changehat_misc.sh
    sed -i "s@genprofile \(.*\)@genprofile \\1 \"/nix/store/*/lib/*.so*:rm\"@g" tests/regression/apparmor/capabilities.sh
    # sed -i "s@genprofile \(.*\)@genprofile \\1 \"/nix/store/*/lib/*.so*:rm\"@g" tests/regression/apparmor/i18n.sh

    # sed -i "s@genprofile \(.*\)@genprofile \\1 \"${libapparmor}/lib/libapparmor.so.1*:rm\"@g" tests/regression/apparmor/sd_flags.sh
    # sed -i "s@genprofile \(.*\)@genprofile \\1 \"${libapparmor}/lib/libapparmor.so.1*:rm\"@g" tests/regression/apparmor/changehat_misc.sh
    # sed -i "s@genprofile \(.*\)@genprofile \\1 \"${libapparmor}/lib/libapparmor.so.1*:rm\"@g" tests/regression/apparmor/i18n.sh
    sed -i "s@/bin/pwd@${lib.getExe' coreutils "pwd"}@g" tests/regression/apparmor/*.sh
  '';

  postPatch = ''
    pushd ./tests/regression/apparmor
  '';

  nativeBuildInputs = [ ];

  makeFlags = [ "USE_SYSTEM=1" ];

  preCheck = "export USE_SYSTEM=1";

  buildInputs =
    [
      attr
      pkg-config
      dbus
      liburing
    ]
    ++ (with flake_packages; [
      apparmor-parser
      apparmor-bin-utils
      apparmor-pam
      libapparmor
    ])
    ++ lib.optional withPerl perl;

  installPhase = ''
    popd
    cp ./tests/regression/apparmor $out -r
  '';

  meta = apparmor-meta "regression test suite";
}
