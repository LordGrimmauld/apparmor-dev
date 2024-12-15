{
  lib,
  aa_pkgs,
  check_pkgs,
  writeShellApplication,
}:
let
  inherit (aa_pkgs) apparmor-bin-utils;
  inherit (check_pkgs) regression-test-src;
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

  blacklist = builtins.concatStringsSep " " (control ++ bad);
in
writeShellApplication {
  name = "aa-reg-test";

  runtimeInputs = [
    regression-test-src
  ];

  text = ''
        tdir=$(mktemp -d)
        cp ${regression-test-src}/* "$tdir" -r
        chmod o+rx -R "$tdir"
        export AA_EXEC=${lib.getExe' apparmor-bin-utils "aa-exec"}
        
        pushd "$tdir" > /dev/null
        
        TEST_BLACKLIST="${blacklist}"
        
        bash check_dac_perms.sh || exit 1
        
        if [ "$(whoami)" = "root" ] ;then
    		    rc=0
        		pass="PASSED:"
            skip="SKIPPED:"
    		    fail="FAILED:"
        		for x in ./*.sh ; do
              i=$(basename -s .sh "$x")
              
     		    	echo
              
              if [[ $TEST_BLACKLIST =~ (^|[[:space:]])$i($|[[:space:]]) ]] ; then
          			echo "skipping blacklisted: $i"
        				skip="$skip $i"
                continue
              fi

        			echo "running $i"
        			if ! bash "$x" ; then
        				rc=1
        				fail="$fail $i"
       		    else
        				pass="$pass $i"
        			fi
        		done
            
        		echo
            echo "$pass"
            echo "$skip"
            if [ "$fail" = "FAILED:" ] ; then
              echo "ALL TESTS PASSED"
            else
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
