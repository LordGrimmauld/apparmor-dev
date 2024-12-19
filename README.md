# What is this?
AppArmor is a Mandatory Access Control solution by cannonical.
Building and developing apparmor on NixOS systems is not trivial. This repo is an attempt to provide the necessary tooling.

# Included Tooling
Currently, this projects provides flake-based tooling to compile, test and use apparmor versions from the upstream gitlab.
Packages provided by the flake follow the package names in nixpkgs but build against (unstable) git versions.
Packages included in this flake have their make checks enabled, which nixpkgs versions of apparmor do not.

Checks provided by this flake test compilation of all packages,
as well as test the nixos VM tests for apparmor and the upstream apparmor regression tests.

Checks are executed on each git push and pull request via nix-github-actions.

An overlay is provided to overlay the nixpkgs versions of apparmor packages with the dev versions.

A nixos module is exposed that simply applies the overlay.

# Caution
dbus, systemd, pam, linux kernel and a couple other low-level packages have dependencies on apparmor. ***Using the overlay or module,
you are losing almost all package caching!*** Further, while i went to great effort to ensure decent test coverage,
i can not guarantee apparmor here working correctly, both in terms of security and stability.
Make sure you have fallbacks, and make sure you do your own due diligence! And if you find an issue, open a report.

# Planned Tooling
A dev shell is planned, but the exact layout of that is not yet decided.

A nixos system output is being considered to easily build an interactive VM to go poke at apparmor things.
