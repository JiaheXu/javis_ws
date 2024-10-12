#!/usr/bin/env bash

# load header helper functions
GL_CMPL_DIR=$JAVIS_OPERATIONS/javis_deploy/automate/
. $JAVIS_OPERATIONS/javis_deploy/automate/header.sh

# TODO: cleanup all these dup help messages...

# //////////////////////////////////////////////////////////////////////////////
# @brief 'javis'
# //////////////////////////////////////////////////////////////////////////////
__ac_javis_help() {
  local usage=(
    "About: 01... == JAVIS == "
    "About: 02... Enabling Enhanced Situational Awareness and Human Augmentation through Efficient Autonomous Systems"
    "About: 03..."
    "About: 04... HowTo:"
    "About: 05...  - Press 'Tab' once, to preview a list of completed word options."
    "About: 06...  - Input a tab-complete word, from the preview list of completed words."
    "About: 07...  - Press '.', TAB to preview the next list of next available deployer actions."
    "About: 08...  - Press SPACE, TAB to show the help message and preview words (for your current completion match)."
    "About: 09... * MAKE SURE THERE IS NO WHITESPACE WHEN YOU SELECT THE NEXT KEYWORD (i.e. press backspace to show tab-complete list)"
    "About: 11..."
    "About: 12... == Optional Flags =="
    "About: 13..."
    "About: 14...   -p           : preview the deployer commands that will be run"
    "About: 15...   -verbose     : show the exact (verbose) bash commands that will run"
    "About: 16..."
    "About: 17... == Your Tab-Completed Word Options Are =="
    "About: 18..."
    "deployer   : deployer -- your access point to 'deploy' javis onto different systems."
    "ansible    : ansible installer scripts."
    "tools      : general tools"
    "hosts      : tool to detect hosts with the host info tool and setup ssh"
    "install    : tools to install and setup the javis stack"
  )
  local IFS=$'\n' # split output of compgen below by lines, not spaces
  usage[0]="$(printf '%*s' "-$COLUMNS"  "${usage[0]}")"
  COMPREPLY=("${usage[@]}")
}

# //////////////////////////////////////////////////////////////////////////////
# @brief 'subt git'
# //////////////////////////////////////////////////////////////////////////////
__ac_git_help() {
  local usage=(
    "About: 01... git helper -- to hide git submodule details."
    "About: 02... - allows for git commands to be run over a group of submodules."
    "About: 03... - tab complete each subcommand to see what arguments are available."
    "About: 04... == Your Options Are =="
    "About: 05... "
    "status   : show the general git info for every submodule."
    "sync     : fetch & syncs the local branches with the remote branches for every submodule."
    "clean    : cleans any uncommitted changes in all submodules."
    "rm       : removes all the submodules in a specific group."
    "reset    : resets group of submodules to their DETACHED HEAD state."
    "pull     : pulls the submodules updates (equivalent to 'git submoudle update --init --recursive')."
    "help     : view help usage message."
  )
  local IFS=$'\n' # split output of compgen below by lines, not spaces
  usage[0]="$(printf '%*s' "-$COLUMNS"  "${usage[0]}")"
  COMPREPLY=("${usage[@]}")
}
__git_help() {
  GL_TEXT_COLOR=$FG_LCYAN
  text
  text_color "usage: subt git [subcommand] "
  text_color
  text_color "== Your Options Are =="
  text_color "status   : show the general git info for every submodule."
  text_color "sync     : fetch & syncs the local branches with the remote branches for every submodule."
  text_color "clean    : cleans any uncommitted changes in all submodules."
  text_color "rm       : removes all the submodules in a specific group."
  text_color "reset    : resets group of submodules to their DETACHED HEAD state."
  text_color "pull     : pulls the submodules updates (equivalent to 'git submoudle update --init --recursive')."
  text_color "help     : view help usage message."
  text_color
  text_color "About: git helper -- to hide git submodule details."
  text_color
  text_color "For more help, please see the README.md or wiki."
  GL_TEXT_COLOR=$FG_DEFAULT
}

# //////////////////////////////////////////////////////////////////////////////
# @brief 'subt tools'
# //////////////////////////////////////////////////////////////////////////////
__ac_tools_help() {
  local usage=(
    "About: 01... == Tools == "
    "About: 02... General helper scripts, can be used local or on robots."
    "About: 03... "
    "About: 04... == Your Tab-Completed Word Options Are == "
    "About: 05... "
    "shh.probe          : shows the ssh connections that are are available to connect."
  )
  local IFS=$'\n' # split output of compgen below by lines, not spaces
  usage[0]="$(printf '%*s' "-$COLUMNS"  "${usage[0]}")"
  COMPREPLY=("${usage[@]}")
}

# //////////////////////////////////////////////////////////////////////////////
# @brief 'subt git status'
# //////////////////////////////////////////////////////////////////////////////
__ac_git_status_help() {
  local usage=(
    "About: 01... Shows a short summary of the git status for all submodules."
    "About: 02...   - i.e. 'dirty' submodule status for any given meta repos."
    "About: 03... == Optional Flags =="
    "About: 04..."
    "About: 06...   -hash         : show 'hash' column in table output"
    "About: 07...   -url          : show 'url' column in table output"
    "About: 08..."
    "About: 09... == Your Options Are =="
    "About: 10... "
    "autonomy       : javis_ws/src/javis_autonomy"
    "cameras        : javis_ws/src/javis_cameras"
    "common         : javis_ws/src/javis_common"
    "loam           : javis_ws/src/javis_loam"
    "drivers        : javis_ws/src/javis_drivers"
    "help           : view help usage message."
  )
  local IFS=$'\n' # split output of compgen below by lines, not spaces
  usage[0]="$(printf '%*s' "-$COLUMNS"  "${usage[0]}")"
  COMPREPLY=("${usage[@]}")
}
__status_help() {
  GL_TEXT_COLOR=$FG_LCYAN
  text
  text_color "usage: status [<flag>] [<flag>]"
  text_color
  text_color "== Optional Flags =="
  text_color "    -hash       : show 'hash' column in table output"
  text_color "    -url        : show 'url' column in table output"
  text_color
  text_color "== Options =="
  text_color "autonomy    : javis_ws/src/javis_autonomy"
  text_color "cameras     : javis_ws/src/javis_cameras"
  text_color "common      : javis_ws/src/javis_common"
  text_color "loam        : javis_ws/src/javis_loam"
  text_color "drivers     : javis_ws/src/javis_drivers"
  text_color "help        : view help usage message"
  text_color "About:"
  text_color "       shows a short summary of the git status for all submodules."
  text_color
  GL_TEXT_COLOR=$FG_DEFAULT
}

# //////////////////////////////////////////////////////////////////////////////
# @brief 'subt git sync'
# //////////////////////////////////////////////////////////////////////////////
__ac_git_sync_help() {
  local usage=(
    "About: 01... Fetch & resets all local branches to its respective origin remote branch commit for all submodules (recursive)."
    "About: 02... == Optional Flags =="
    "About: 03..."
    "About: 04...   -del         : delete any local branches not found on the origin remote."
    "About: 05...   -hard        : sync the current checked-out branch."
    "About: 06... == Your Options Are =="
    "About: 07... "
    "autonomy       : javis_ws/src/javis_autonomy"
    "cameras        : javis_ws/src/javis_cameras"
    "common         : javis_ws/src/javis_common"
    "loam           : javis_ws/src/javis_loam"
    "drivers        : javis_ws/src/javis_drivers"
    "help           : view help usage message."
  )
  local IFS=$'\n' # split output of compgen below by lines, not spaces
  usage[0]="$(printf '%*s' "-$COLUMNS"  "${usage[0]}")"
  COMPREPLY=("${usage[@]}")
}
__sync_help() {
  GL_TEXT_COLOR=$FG_LCYAN
  text
  text_color "usage: sync [<flag>] [<flag>] "
  text_color
  text_color "== Optional Flags =="
  text_color "  -del            : delete any local branches not found on the origin remote."
  text_color "  -hard           : sync the currently checkout branch."
  text_color
  text_color "== Options =="
  text_color "autonomy    : javis_ws/src/javis_autonomy"
  text_color "cameras     : javis_ws/src/javis_cameras"
  text_color "common      : javis_ws/src/javis_common"
  text_color "loam        : javis_ws/src/javis_loam"
  text_color "drivers     : javis_ws/src/javis_drivers"
  text_color "help        : view help usage message"
  text_color
  text_color "About:"
  text_color "      Fetch & resets all local branches to its respective origin remote branch commit for all submodules (recursive)."
  text_color
  GL_TEXT_COLOR=$FG_DEFAULT
}

# //////////////////////////////////////////////////////////////////////////////
# @brief 'javis ansible'
# //////////////////////////////////////////////////////////////////////////////
__ac_ansible_help() {
  local usage=(
    "About: 00... == Ansible =="
    "About: 01... Installs base system library dependencies, extra tools & sets up system configuration on the different systems."
    "About: 02... - personalize your install by changing the options here: ~/.javis/ansible_cfg.yaml"
    "About: 03..."
    "About: 11... Flags:"
    "About: 12...   -s  : Show the available system names."
    "About: 13...   -b  : Show the available playbooks."
    "About: 14...   -p  : Provide system password, to allow sudo installs."
    "About: 15... Args:"
    "About: 16...   system_name: the name of the remote system to install on"
    "About: 17...   playbook: the name of the robot ansible playbook to run"
    "About: 18... Input: "
    "About: 19...   [ flags ] < system_name > < playbook > "
    "             "
  )
  local IFS=$'\n' # split output of compgen below by lines, not spaces
  usage[0]="$(printf '%*s' "-$COLUMNS"  "${usage[0]}")"
  COMPREPLY=("${usage[@]}")
}

__ac_submenu_help() {
  local _subcommand=$1
  local _prev=$2
  local _result=$(perl $GL_CMPL_DIR/cmpl/cmpl.pl "${_subcommand}_help" "$_prev")
  # split resulting string based on newlines
  SAVEIFS=$IFS        # save current IFS, so we can revert back to it
  IFS=$'\n'           # change IFS to split on new lines
  _result=($_result)
  IFS=$SAVEIFS        # revert to old IFS

  local IFS=$'\n' # split output of compgen below by lines, not spaces
  _result[0]="$(printf '%*s' "-$COLUMNS"  "${_result[0]}")"
  COMPREPLY=("${_result[@]}")
}
