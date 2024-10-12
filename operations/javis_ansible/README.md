# JAVIS Ansible
Scripts and configuration to install the javis stack.

## Playbooks
Ansible playbooks that can install stuff!
```
playbooks/install.yaml         # installs a variety of dependencies and whatnot for running javis
playbooks/install_min.yaml     # Installs local config used for running sims / building / etc...
playbooks/install_global.yaml  # Installs global config to run and deploy on multiple robots
playbooks/setup_payload.yaml   # /etc/payload/serial & /etc/payload/type
```

### playbooks/deploy
These playbooks are related to things in the javis_ugv repo.
This includes:
- installing the deployer tool
- installing host info tools
- installing stuff in /etc/javis
- installing stuff in ~/.javis
- etc...

### playbooks/misc
A lot of various dependencies and toolas needed by the javis stack eg:
- docker
- docker-compose
- nvidia-docker
- ros

### playbooks/facts
This is just playbooks that collects and set facts from the remote host

### playbooks/files
These are basically all templates to be filled out by the above playbooks


# Improvements:
- don't like that there is still install stuff in javis-setup.bash (for docker)
- don't like that the way paths are being handled in playbooks/facts/setup_vars.yaml
    that reeks of something that is going to get messed up later on

# MISC
Among the many files the install touches are `~.tmux.conf`, if you don't want it to touch it add the following line to the tmux.conf
```
# JAVIS INSTALL NO TOUCHIE
```
