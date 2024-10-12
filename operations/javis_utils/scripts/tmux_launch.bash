#!/usr/bin/env bash

. "$JAVIS_OPERATIONS/javis_utils/scripts/header.sh"
. "$JAVIS_OPERATIONS/javis_utils/scripts/formatters.sh"

if chk_flag --help $@ || chk_flag help $@ || chk_flag -h $@; then
  GL_TEXT_COLOR=$FG_LCYAN
  text
  title "Usage: $(basename $0) [ flag ]  < arguments >  "
  text_color "Flags:"
  text_color "      -st < ssh connection > < robot name >  < tmux yaml >  :   start a tmux sessesion. "
  text_color "      -sp < ssh connection > < robot name >  < tmux yaml >  :   stop a tmux sessesion. "
  text_color "      -a  < ssh connection >                                :   attach a tmux sessesion. "
  text_color "      -d  < ssh connection >                                :   detach a tmux sessesion. "
  text_color
  text_color "Tmux launch script wrapper run on remote system. Ysed by desktop icons, to start, stop, attach or detach robot tmux launches."
  text_color "For more help, please see the README.md or wiki."
  GL_TEXT_COLOR=$FG_DEFAULT
  exit_success
fi

##
# validate given enough arguments, for start and stop options
##
function validate_load_args() {
  args=($@)
  if (( ${#args[@]} < 3)); then
    print_error "Error: Not enough arguments. Required: 3, given: ((${#args[@]} - 1))"
    exit_failure
  fi
}

##
# validate given enough arguments, for attach and detach options
##
function validate_detach_args() {
  args=($@)
  if (( ${#args[@]} < 2)); then
    print_error "Error: Not enough arguments. Required: 3, given: ((${#args[@]} - 1))"
    exit_failure
  fi
}

# //////////////////////////////////////////////////////////////////////////////
# @main entrypoint
# //////////////////////////////////////////////////////////////////////////////

# start the tmux session
if chk_flag -st $@ ; then

  # get the arguments after the flag
  validate_load_args "$@"
  args=(${@:$(( $( idx -st $@) + 2 ))})

  # start the tmux session over ssh
  ssh -t ${args[0]} "ROBOT=${args[1]} source ~/.javis/javisrc.sh && tmuxp load ~/javis_ws/operations/javis_deploy/tmux/${args[2]}.start.yaml"

  # exit on failure if ssh tmux, 'start' launch failed
  if last_command_failed; then
    error "ssh tmux attach session failed: (conn) ${args[0]} , (robot) ${args[1]}, (yaml) ${args[2]} "
    exit_failure
  fi

# stop the tmux session
elif chk_flag -sp $@ ; then
  # get the arguments after the flag
  validate_load_args "$@"
  args=(${@:$(( $( idx -sp $@) + 2 ))})

  # stop the tmux session over ssh
  ssh -t ${args[0]} "ROBOT=${args[1]} source ~/.javis/javisrc.sh && tmuxp load ~/javis_ws/operations/javis_deploy/tmux/${args[2]}.stop.yaml"

  # exit on failure, if ssh tmux 'stop' launch failed
  if last_command_failed; then
    error "ssh tmux attach session failed: (conn) ${args[0]} , (robot) ${args[1]}, (yaml) ${args[2]} "
    exit_failure
  fi

# attach the tmux session
elif chk_flag -a $@ ; then
  # get the arguments after the flag
  validate_detach_args "$@"
  args=(${@:$(( $( idx -a $@) + 2 ))})

  # attach the tmux session over ssh
  ssh -t ${args[0]} "tmux attach -t ${args[1]}"

  # exit on failure, if ssh tmux 'attach' launch failed
  if last_command_failed; then
    error "ssh tmux attach session failed: (conn) ${args[0]} , (session) ${args[1]} "
    exit_failure
  fi

# detach the tmux session
elif chk_flag -d $@ ; then
  # get the arguments after the flag
  validate_detach_args "$@"
  args=(${@:$(( $( idx -d $@) + 2 ))})

  # detach the tmux session over ssh
  ssh -t ${args[0]} "tmux detach -s ${args[1]}"

  # exit on failure, if ssh tmux 'detach' launch failed
  if last_command_failed; then
    error "ssh tmux attach session failed: (conn) ${args[0]} , (session) ${args[1]} "
    exit_failure
  fi

# playback the tmux session
elif chk_flag -ply $@ ; then
  # get the arguments after the flag
  validate_load_args "$@"
  args=(${@:$(( $( idx -ply $@) + 2 ))})

  # stop the tmux session over ssh
  ssh -t ${args[0]} "ROBOT=${args[1]} tmuxp load ~/javis_ws/operations/javis_deploy/tmux/${args[2]}.playback.yaml"

  # exit on failure, if ssh tmux 'stop' launch failed
  if last_command_failed; then
    error "ssh tmux attach session failed: (conn) ${args[0]} , (robot) ${args[1]}, (yaml) ${args[2]} "
    exit_failure
  fi

fi

exit_success
newline
