{
  lib,
  flake_packages,
  writeShellApplication,
}:
let
  inherit (flake_packages)
    libapparmor
    apparmor-bin-utils
    regression-tests
    ;
in
writeShellApplication {
  name = "aa-reg-test";

  runtimeInputs = [
    regression-tests
    libapparmor
  ];

  text =
    let
      removeAll = r: l: if r == [ ] then l else lib.remove (lib.head r) (removeAll (lib.tail r) l);
      all_tests = map (lib.removeSuffix ".sh") (
        builtins.attrNames (
          lib.filterAttrs (n: v: (lib.hasSuffix ".sh" n) && (v == "regular")) (
            builtins.readDir regression-tests
          )
        )
      );
      control = [
        "aa_exec_wrapper"
        "check_dac_perms"
      ];
      bad = [
        "owlsm"
        "env_check"
        "attach_disconnected"
        "capabilities"
        "unix_socket_pathname"
      ];

      tests = builtins.concatStringsSep " " (removeAll (control ++ bad) all_tests);
    in
    ''
          tdir=$(mktemp -d)
          cp ${regression-tests}/* "$tdir" -r
          chmod o+rx -R "$tdir"
          export AA_EXEC=${lib.getExe' apparmor-bin-utils "aa-exec"}
          
          pushd "$tdir" > /dev/null
          
          TESTS="${tests}"
          RISKY_TESTS=""
          
          bash check_dac_perms.sh || exit 1
          
          if [ "$(whoami)" = "root" ] ;then
      		    rc=0
          		pass="PASSED:"
      		    fail="FAILED:"
          		for i in $TESTS $RISKY_TESTS ; do
       		    	echo
          			echo "running $i"
          			if ! bash "$i.sh" ; then
          				rc=1
          				fail="$fail $i"
         		    else
          				pass="$pass $i"
          			fi
          		done
              
          		echo
              if [ "$fail" = "FAILED:" ] ; then
                echo "$pass"
                echo "ALL TESTS PASSED"
              else
            		echo "$pass"
            		echo "$fail"
              fi
              
              popd > /dev/null
              if [ "$rc" = "0" ] ; then
                exit 0
              else
                exit 1
              fi
          	else
          		echo "must be root to run tests"
              popd
          		exit 1
          	fi
    '';
}
