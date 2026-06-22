# Getting Started

The JAVIS workspace uses Ansible, Docker, Docker Compose, tmux/tmuxp, and internal deployment tools to install and run the robot stack across Jetson Orin payload computers and x86 basestation/development machines.

For a fresh machine, follow the detailed checklist first:

- [Fresh install checklist](fresh_install_checklist.md)

## Install Overview

The normal install order is:

```bash
cd ~/javis_ws
source ./javis-setup.bash
javis install
javis install --global
```

On payload computers, also run:

```bash
javis install --payload
```

The three installer modes have different responsibilities:

- `javis install` installs local packages, Docker tooling, Python tools, launch helpers, and workspace configuration.
- `javis install --global` writes the host's JAVIS identity and enables host discovery for deployment.
- `javis install --payload` writes payload serial/type identity under `/etc/payload`.

Jetson Orin payloads and x86 basestations use the same commands, but platform facts and selected system parameters determine which host type and Docker images are used.

## Workspace Environment

Source the setup script in every new shell until your shell startup file has been configured by the installer:

```bash
source ./javis-setup.bash
```

This exports paths such as `JAVIS_PATH`, adds operations tools to `PATH`, and enables the `javis` command.

On a fresh machine, warnings about missing `~/.javis` or install config are expected before `javis install` has completed.

## Submodules

At minimum, initialize operations before running the installer:

```bash
git submodule update --init --recursive operations
```

Initialize `src/*` submodules according to the packages you need to build or run. Some private SLAM/perception dependencies may require separate access, so avoid blindly initializing unavailable submodules on a fresh robot.

## Build And Launch

After install and reboot:

```bash
source ~/.bashrc
javis deployer local.make
javis deployer local.start
javis deployer local.core.build
```

Launch examples are documented in [howto_launch.md](howto_launch.md).

## Verify Installation

Useful non-destructive checks:

```bash
echo "$JAVIS_PATH"
echo "$JAVIS_HOST_TYPE"
echo "$JAVIS_ARCH_T"
docker --version
docker ps
hit params
javis hosts
```

For common failures, see [common_errors.md](common_errors.md).
