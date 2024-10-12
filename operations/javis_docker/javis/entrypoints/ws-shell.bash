#!/usr/bin/env bash
# //////////////////////////////////////////////////////////////////////////////
# docker entrypoint script
# //////////////////////////////////////////////////////////////////////////////
set -e

usermod -u $JAVIS_USERID developer
usermod -g $JAVIS_GROUPID developer

# log message
echo " == Workspace Shell == "

# Install the deploy workspace
echo " ==  Install The JAVIS Workspace =="



# setup roscore IP/hostnames and source the project workspaces
_SET_ROSCORE=true
_SET_WS=true

_SET_ROS2="\$SET_ROS2"

_ROS_WS="\$ROS_SOURCED_WORKSPACE"
_ROS_DISTRO="\$JAVIS_ROS_DISTRO"
source /docker-entrypoint/roscore-env-setup.bash

# Should be done after the roscore setup - roscore setup removes javis setup
cd ~/javis_ws/
./javis-setup.bash --docker-setup

# source the bashrc -- so we have the deploy_ws path set
source ~/.javis/auto/javis_redirect.bash

# source the bashrc again -- to set the added ros variables
source ~/.bashrc

# Disallow docker exit -- keep container running
echo "Entrypoint ended";
/bin/bash "$@"
