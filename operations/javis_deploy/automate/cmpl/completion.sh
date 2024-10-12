#!/usr/bin/env bash

# load header helper functions
GL_CMPL_DIR=$JAVIS_OPERATIONS/javis_deploy/automate/
. $JAVIS_OPERATIONS/javis_utils/scripts/header.sh
. $JAVIS_OPERATIONS/javis_deploy/automate/header.sh
. $JAVIS_OPERATIONS/javis_deploy/automate/cmpl/help.sh

##
# @brief find the auto-complete help results (expanded from deployer sections)
##
ac_matcher_help() {
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

##
# @brief find the the current auto-complete token matches
##
ac_matcher() {
  local _matcher_t=$1 _curr=$2
  [[ "$_curr" == "" ]] && return 1  # if not given a current token, then show the help usage message
  # evaluate the matcher
  local _result=$(perl $GL_CMPL_DIR/cmpl/cmpl.pl "$_matcher_t" "$_curr")
  local _term_t=$(ps -p$$ -ocmd=)
  if [ ! -z "$_result" ]; then
    [ "$_term_t" = "bash" ] && COMPREPLY=( $( compgen -W "$_result" -- "$_str" ) ) && compopt -o nospace && return 0
    [ "$_term_t" = "zsh" ]  && COMPREPLY=( $( compgen -W "$_result" -- "$_str" ) ) && return 0
  fi
  return 1
}

# //////////////////////////////////////////////////////////////////////////////
# @brief tab autocompletion for javis 'command center'
#   - three level menu of subcommands
# //////////////////////////////////////////////////////////////////////////////
_ac_javis_completion() {

  COMPREPLY=() # initialize completion result array.

  # Retrieve the current command-line token, i.e., the one on which completion is being invoked.
  local _curr=${COMP_WORDS[COMP_CWORD]}
  local _prev=${COMP_WORDS[COMP_CWORD-1]}

  # a finished subcommand argument does not have a trailing '.'
  #   - if so, then reset prev to the subcommand name.
  if [ $COMP_CWORD -gt 1 ]; then
    [ ! ${_prev: -1} == "." ] && _prev=${COMP_WORDS[2]}
  fi

  # first level menu: 'javis'
  if [ $COMP_CWORD = 1 ]; then
    ! ac_matcher "javis" $_curr && __ac_javis_help

  # second level menu: 'javis <subcommand> '
  elif [ $COMP_CWORD = 2 ]; then
    # tools menu
    if chk_flag tools "${COMP_WORDS[@]}"; then
      ! ac_matcher "tools" $_curr && __ac_tools_help

    # deployer menu
    elif chk_flag deployer "${COMP_WORDS[@]}"; then
      ! ac_matcher "deployer" $_curr && ac_matcher_help "deployer" "deployer"

    # git menu
    elif chk_flag git "${COMP_WORDS[@]}"; then
      ! ac_matcher "git" $_curr && __ac_git_help

    # ansible menu
    elif chk_flag ansible "${COMP_WORDS[@]}"; then
      ! ac_matcher "ansible" $_curr && __ac_ansible_help

    # 'javis <subcommand>' match failed -- show display usage help menu
    else
      __ac_javis_help
    fi

  # third level menu: 'javis <subcommand> <subcommand> '
  else

    # third level 'javis git'
    if chk_flag git "${COMP_WORDS[@]}"; then

      if chk_flag status "${COMP_WORDS[@]}"; then
        ! ac_matcher "git_status" "$_curr" && __ac_git_status_help
      elif chk_flag sync "${COMP_WORDS[@]}"; then
        ! ac_matcher "git_sync" "$_curr" && __ac_git_sync_help
      elif chk_flag reset "${COMP_WORDS[@]}"; then
        ! ac_matcher "git_reset" "$_curr" && ac_matcher_help "git_reset" $_prev
      elif chk_flag pull "${COMP_WORDS[@]}"; then
        ! ac_matcher "git_pull" "$_curr" && ac_matcher_help "git_pull" $_prev
      elif chk_flag rm "${COMP_WORDS[@]}"; then
        ! ac_matcher "git_rm" "$_curr" && ac_matcher_help "git_rm" $_prev
      elif chk_flag clean "${COMP_WORDS[@]}"; then
        ! ac_matcher "git_clean" "$_curr" && ac_matcher_help "git_clean" $_prev
      fi

    # third level 'javis ansible'
    elif chk_flag ansible "${COMP_WORDS[@]}"; then
      ! ac_matcher "ansible" "$_curr" && ac_matcher_help "ansible" $_prev

    # third level 'javis deployer'
    elif chk_flag deployer "${COMP_WORDS[@]}"; then
      ! ac_matcher "deployer" $_curr && ac_matcher_help "deployer" $_prev
    fi
  fi
}
