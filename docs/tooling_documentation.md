# Tooling Documentation
There are many tools used by javis for deployment, testing, and development.

There is a lot of information here - if there are things you are unfamiliar with I recommend you go down the list of each tool and run throught the tutorial linked at the top and consider printing out a cheat sheet if there is one.

This repo has an extensive list of documentation on command line and many other tools. It encompasses much of the information in the below links.
- [Extensive Ubuntu / Tooling Documentation](https://github.com/JREAM/ubuntu-cheatsheet)

## Terminal
A lot of the tools that javis uses are focused around the linux command line, or terminal. It is recommened you familiarize yourself with command line usage as you will be using the terminal a LOT.

- [Ubuntu Command Line Tutorial](https://ubuntu.com/tutorials/command-line-for-beginners#1-overview)
- [Good Basic Cheat Sheets](https://garywoodfine.com/linux-terminal-command-cheat-sheets/)
- [Server Commands Cheat Sheet](https://assets.ubuntu.com/v1/f401c3f4-Ubuntu_Server_CLI_pro_tips_2020-04.pdf)

## GIT
Git is a source management tool that allows use to track different versions of code, revert to old versions of code, and deploy new versions.

- [Beginner Tutorial](https://www.atlassian.com/git/tutorials/what-is-version-control)
- [Cheat Sheet](https://education.github.com/git-cheat-sheet-education.pdf)
- [Official Documentation](https://git-scm.com/doc)

## Tmux
Tmux is a tool that allows us to have multiple console panes in a single terminal window.

- [Extensive Introduction](https://leimao.github.io/blog/Tmux-Tutorial/)
- [Cheet Sheet](https://tmuxcheatsheet.com/)
- [Man Page](https://man7.org/linux/man-pages/man1/tmux.1.html)
- [Official Documentation](https://tmuxp.git-pull.com/about_tmux.html)

NOTE: By default we install a custom tmux configuration. If you would like to have the default configuration or set your own configuration and not have javis install override it - please place the following line in your `~.tmux.conf`

```
# JAVIS INSTALL NO TOUCHIE
```

## Tmuxp
Tmuxp is a tool that wraps around tmux and provides a nice interface for reproducing tmux configurations in terminal. It allows us to programmatically launch several commands in parallel in a reproducible way.

You probably don't need to understand this one as much, until you go to define your own launch configurations you will probably just use existing configurations.

- [Official Documentation](https://tmuxp.git-pull.com/)
- [Documentation PDF (same thing basically)](https://buildmedia.readthedocs.org/media/pdf/tmuxp/latest/tmuxp.pdf)

## Docker 
Docker is a tool that allow us to conveniently package dependencies into a format that can be deployed to other machines in a very reproducable way.

NOTE: docker image building and deployment has been abstracted away with the deployer tools.

- [Introduction / Tutorial](https://docker-curriculum.com/)
- [Official Documentation](https://docs.docker.com/)
- [Cheat Sheet](https://www.docker.com/sites/default/files/d8/2019-09/docker-cheat-sheet.pdf)

The docker-compose tutorial also has a good brief overview of docker at the beginning.

## Docker-Compose
Docker compose allows us to define docker configurations in a manner similar to tmuxp does with tmux.

- [Tutorial](https://www.educative.io/blog/docker-compose-tutorial)
- [Official Documentation](https://docs.docker.com/compose/)
- [Cheat Sheet](https://devhints.io/docker-compose)

## Internal Tools
For completeness I will list some tools that were developed internally that are used for this project.

### Deployer
The deployer tools is able to automate the execution of multiple lists of commands in a programmatic way. It has been used to automate deployment of code to other robots, automate the building of docker, automate the building of the workspace and more.

At the time of writing this I do not have extensive documentation on this tooling.

### Host Info Tools
The host info tools toolset allows us to broadcast and see the information of other hosts on the network. This allows payloads to automatically be seen by basestations.

The [javis-hosts script](../operations/javis_utils/scripts/javis-hosts) wraps around the host info tools and allows us to interface with JAVIS specfic hosts.

For more on host management see the docs [here](host_management.md)

## Linux Configuration
These are some linux configuration and management tools which some parts of the stack use. You probably don't need to review a lot of this, but it is here if you need to modify this configuration.

### Netplan
Starting ubuntu 18.04(?) some new network tools were introduced, specifically `netplan` and `ip`.

- [Netplan tutorial / configuration](https://vitux.com/how-to-configure-networking-with-netplan-on-ubuntu/)
- [ip command cheat sheet](https://access.redhat.com/sites/default/files/attachments/rh_ip_command_cheatsheet_1214_jcs_print.pdf)

### Multicast
Multicast support / configuration is somewhat confusing. These links contain some explanation of how it works.
- [Configurating Linux for Multicast](https://tldp.org/HOWTO/Adv-Routing-HOWTO/lartc.multicast.html)
- [More explanation on stackoverflow](https://serverfault.com/questions/814259/use-ip-route-add-to-add-multicast-routes-to-multiple-interfaces)
- [netstat -g command](https://www.lifewire.com/netstat-command-2618098)