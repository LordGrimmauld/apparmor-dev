{
  lib,
  python3,
  ...
}:
{
  version = "0-unstable-2024-12-10";

  apparmor-meta =
    component: with lib; {
      homepage = "https://apparmor.net/";
      description = "Mandatory access control system - ${component}";
      license = with licenses; [
        gpl2Only
        lgpl21Only
      ];
      maintainers = with maintainers; [
        grimmauld
      ];
      platforms = platforms.linux;
    };

  doCheck = false;

  python = python3.withPackages (ps: with ps; [ setuptools ]);
}
