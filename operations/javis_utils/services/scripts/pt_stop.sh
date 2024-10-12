#!/usr/bin/env bash

# source the javis environment
source ~/.javis/javisrc.sh

# setup username for script
username='javis'

# get the robotname from hostname (remove the javis prefix)
robot_hostname=$(hostname)
robot=${robot_hostname#"javis-"}

# Starts drivers in the docker container
robot=${robot} tmuxp load -d /home/javis/javis_ws/operations//javis_deploy/tmux/pt-orin.stop.yaml
