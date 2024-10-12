#!/usr/bin/env bash

# load header helper functions
. "$JAVIS_OPERATIONS/javis_utils/scripts/header.sh"
. "$JAVIS_OPERATIONS/javis_utils/scripts/formatters.sh"

if chk_flag --help $@ || chk_flag help $@ || chk_flag -h $@; then
  GL_TEXT_COLOR=$FG_LCYAN
  text
  title "Usage: $(basename $0) [flag] [ optional docker join options ] "
  text_color "Flags:"
  text_color "      -help                     : shows usage message."
  text_color "      -n < container name >     : joins the docker container with given name as an argument."
  # text_color "      -o < options >            : additional, docker exec options."
  text_color "      -a                        : attach to a running tmux session."
  text_color ""
  text_color "Joins the docker container -- docker exec enters the containers as a /bin/bash or attach to tmux session."
  text_color "For more help, please see the README.md or wiki."
  GL_TEXT_COLOR=$FG_DEFAULT
  exit_success
fi

# globals
_GL_pwd="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
_GL_exec_cmd="/bin/bash"

# //////////////////////////////////////////////////////////////////////////////
# @brief: script main entrypoint
# //////////////////////////////////////////////////////////////////////////////
main Docker Join
pushd $_GL_pwd

# verify user has given the '--name' flag
if ! chk_flag -n $@; then
  error docker-join missing name flag and argument. Plase run '--help' for usage details.
  exit_failure;
fi

# set the docker-exec to connect to a tmux session, instead of /bin/bash
if chk_flag -a $@; then
  _GL_exec_cmd="tmux a"
fi

# get the docker container name
container=$(get_arg -n $@)

text ...joining container: $container
text

# verify the docker container exists
if [[ "$(docker ps -a | grep ${container})" == "" ]]; then
  error "Docker container, '${container}' does not exist. "
  exit_failure;
fi

# prepare: start the docker container
docker_start_command="docker start ${container}"

# start the container -- handle any container errors
if [[ "$(docker inspect -f {{.State.Running}} ${container})" == false ]]; then
  warning "Docker container, '${container}' is not started, starting the container."
  # preview the docker start command
  subtitle "docker start: " "${docker_start_command}"

  # start the docker container (if not already started)
  eval ${docker_start_command}

  # verify docker start succeeded
  if last_command_failed; then
    echo ${systems[@]}  # gets the last error message, since systems is expecting an echo return
    error Something went wrong. Please check your docker container.
    exit_failure
  fi
fi

# prepare: docker execute /bin/bash to the docker container (with default below options)
docker_execute_command="
  docker exec
    --privileged
    -e DISPLAY=${DISPLAY}
    -e LINES=`tput lines`
    -it ${container}
    $_GL_exec_cmd"

# preview the docker exec command
subtitle "${docker_execute_command} "
subtitle
title "== Docker Container == \n "
subtitle "!! You are inside the docker container '${container}' !! "
newline
subtitle "Catkin: \n"
subtitle "  - Your catkin workspace should be automatically sourced. \n"
subtitle "  - If not, check that you have build the workspace. "
newline
subtitle "Docker Networking: \n"
subtitle "  - Robot containers use the roobot computer host's networking. \n"
subtitle "  - You should be able to ping any of the IPs from your localhost (outside docker) or from any other container (inside docker). "
newline
subtitle "Directories: \n "
subtitle "  - The javis workspace is mounted inside the container. \n"
subtitle "  - So you can edit files in 'javis_ws' using your editor and see the changes inside the container. \n"
subtitle "  - To add other files inside the container, just add to 'javis_ws' and will see the files inside the container. "
newline
subtitle "For more information, please see readme. \n"
newline

# access control disabled, clients can connect from any host
xhost +

# execute the docker exec command, if not in 'preview' mode
if ! chk_flag --preview $@ && ! chk_flag -p $@; then
  eval ${docker_execute_command}
fi

# cleanup & exit
newline
# access control enabled, only authorized clients can connect
xhost -
exit_pop_success
