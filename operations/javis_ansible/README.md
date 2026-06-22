# JAVIS Ansible

Scripts and configuration used by `javis install` to install and configure the JAVIS stack on Jetson Orin payload computers and x86 basestation/development machines.

## Playbooks

Primary playbooks:

```
playbooks/install.yaml         # installs a variety of dependencies and whatnot for running javis
playbooks/install_min.yaml     # Installs local config used for running sims / building / etc...
playbooks/install_global.yaml  # Installs global config to run and deploy on multiple robots
playbooks/setup_payload.yaml   # /etc/payload/serial & /etc/payload/type
```

`install.yaml`, `install_min.yaml`, and `install_global.yaml` all start with `playbooks/misc/pre_run_checks.yaml`. Keep early, non-destructive install validation there so fresh robot installs fail before the installer performs expensive or confusing system changes.

### playbooks/deploy

These playbooks are related to this JAVIS workspace.
This includes:

- installing the deployer tool
- installing host info tools
- installing stuff in /etc/javis
- installing stuff in ~/.javis
- etc...

### playbooks/misc

Dependencies and host setup needed by the JAVIS stack, for example:

- docker
- docker-compose
- nvidia-docker
- ros

`misc/pre_run_checks.yaml` owns bootstrap checks such as sudo validation, apt availability, required workspace paths, and required local commands.

### playbooks/facts

Fact playbooks collect host information for later install decisions:

- `facts/platform_facts.yaml`: Ubuntu release, architecture, GPU/Jetson detection, `javis_arch_type`, and Jetson L4T facts.
- `facts/setup_vars.yaml`: workspace and JAVIS config paths.
- `facts/payload_facts.yaml`: `/etc/payload/type` and `/etc/payload/serial`.

### playbooks/files

Templates filled by the playbooks, including generated config under `/etc/javis` and `~/.javis`.

## Installer Ownership

- `javis-setup.bash` should source environment and report install/version warnings.
- `operations/javis_utils/scripts/javis-install` should parse install options and select Ansible playbooks.
- Ansible playbooks should perform system mutation and host validation.
- Docker image selection should continue to come from `operations/javis_docker` and generated JAVIS host facts.

Known future cleanup: move any remaining install behavior out of `javis-setup.bash` only after the fresh Orin install path is stable.

# MISC

Among the many files the install touches are `~.tmux.conf`, if you don't want it to touch it add the following line to the tmux.conf

```
# JAVIS INSTALL NO TOUCHIE
```
