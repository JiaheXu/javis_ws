# JAVIS Workspace

This repository contains the JAVIS robot workspace plus the operations tooling used to install, build, deploy, and launch the stack on Jetson Orin payload computers and x86 basestation/development machines.

Start here:

- Fresh robot install: [docs/fresh_install_checklist.md](docs/fresh_install_checklist.md)
- General setup flow: [docs/getting_started.md](docs/getting_started.md)
- Launching the stack: [docs/howto_launch.md](docs/howto_launch.md)
- Host discovery and adoption: [docs/host_management.md](docs/host_management.md)
- Common install/runtime errors: [docs/common_errors.md](docs/common_errors.md)

Important entrypoints:

- `source ./javis-setup.bash` exports the workspace environment and enables the `javis` command.
- `javis install` installs local system dependencies and workspace tooling.
- `javis install --global` configures this host's JAVIS identity for deployment.
- `javis install --payload` configures payload identity under `/etc/payload`.
