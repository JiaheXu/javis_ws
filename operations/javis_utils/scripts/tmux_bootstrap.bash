#!/usr/bin/env bash
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
eval "$(cat $__dir/../../javis_utils/scripts/header.sh)"
eval "$(cat $__dir/../../javis_utils/scripts/formatters.sh)"

if chk_flag --help $@ || chk_flag help $@ || chk_flag -h $@; then
  GL_TEXT_COLOR=$FG_LCYAN
  text
  title "Usage: $(basename $0) [ -h ] [ -sp ] [ -ar ] [ -st ] -- < container1 >  < container2 > ...  "
  text_color "Flags:"
  text_color "      -h      : shows usage message."
  text_color "      -sp     : stop the listed containers"
  text_color "      -ar     : restart the argus argus "
  text_color "      -st     : start the listed containers"
  text_color
  text_color "Boostrap script for tmux before_script calls. Used to start or stop containters."
  text_color "For more help, please see the README.md or wiki."
  GL_TEXT_COLOR=$FG_DEFAULT
  exit_success
fi

# //////////////////////////////////////////////////////////////////////////////
# @main entrypoint
# //////////////////////////////////////////////////////////////////////////////
# TODO: make nicer...i.e. without the arg index

function do_ar() {
  text "Restarting services."
  echo passme24 | sudo -S systemctl restart nvargus-daemon.service
  echo passme24 | sudo -S systemctl restart nmea_broadcaster.service
}

# get index of start of arguments.
sidx=$(($(get_idx -- $@) + 2))
if last_command_failed; then
  if chk_flag -ar $@; then
    do_ar
    exit 0
  fi

  echo "Please separate the docker container list from arguments using '--', see help."
  exit_failure
fi

# stop the docker container
if chk_flag -sp $@ ; then
  for name in "${@:$sidx}"; do
    text "Stopping docker container: $name"
    docker stop "$name"
  done
fi

if chk_flag -ar $@; then
  do_ar
fi

# start the docker container
if chk_flag -st $@ ; then
  for name in "${@:$sidx}"; do
    text "Starting docker container: $name"
    docker start "$name"
  done
  sleep 5
fi

# cleanup & exit
exit_success
