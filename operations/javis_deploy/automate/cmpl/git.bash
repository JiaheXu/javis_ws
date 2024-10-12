#!/usr/bin/env bash
GL_CMPL_DIR=$JAVIS_OPERATIONS/javis_deploy/automate/
. "$GL_CMPL_DIR/.header.bash"
. "$GL_CMPL_DIR/.help.bash"

if chk_flag --help $@ || chk_flag help $@ || chk_flag -h $@; then
  GL_TEXT_COLOR=$FG_LCYAN
  text
  text_color "Usage: <subcommand> [flag] [flag] ... "
  text
  text_color "Subcommand:"
  text_color "      status : shows the git status for all submodules."
  text_color "      clone : clone."
  text_color "      reset : Removes all snapshot logfiles in operations/field_testing/*.log"

  # show flags for specific subcommand
  if chk_flag status $@; then
    __status_help
  elif chk_flag sync $@; then
    __sync_help
  elif chk_flag add $@; then
    __add_help
  fi

  text_color "For more help, please see the README.md or wiki."
  GL_TEXT_COLOR=$FG_DEFAULT

  exit_success
fi

# globals
GL_STATUS_HASH=false
GL_STATUS_URL=false
GL_SYNC_DELETE_BRANCH=false
GL_SYNC_IGNORE_CURR=true
GL_OPTS=""

# //////////////////////////////////////////////////////////////////////////////
# @brief git status
# //////////////////////////////////////////////////////////////////////////////

##
# @brief displays the 'git status' of a submodule
##
__status() {
  # printf colors
  local _pfred=$(tput setaf 1)
  local _pfblue=$(tput setaf 4)
  local _pfnormal=$(tput sgr0)

  # collect git submodule status information
  local _submodule=$(realpath --relative-to="$JAVIS_SRC_PATH" "$(pwd)")
  local _hash=$(git rev-parse --verify HEAD)
  local _branch=$(git rev-parse --abbrev-ref HEAD)
  local _url=$(git config --get remote.origin.url)
  local _dirty=$(git_is_dirty)
  local _untrack=$(git_ntracked)
  local _uncommit=$(git_ncommit)
  local _status=""

  # determine the type of output display format for detached or non-detached head
  [[ "$_branch" != "HEAD" ]] && _branch="$_pfblue$_branch$_pfnormal" || _branch="$_pfnormal-$_pfnormal"

  # check if git submodule has any untracked files
  [[ "$_untrack" != "0" ]] && _status=" $_untrack _untrack"

  # check if git submodule status is dirty
  [[ "$_dirty" = "*" ]] && _status="$(git diff --shortstat), $_untrack untrack"

  # display submodule information as a column table print style

  printf "%-50s | %-52s | %-15s " "$_submodule" "$_branch" "$_pfred$_status$_pfnormal"
  [[ $GL_STATUS_HASH == true ]] && printf " | %-30s" "$_hash"
  [[ $GL_STATUS_URL == true ]]  && printf " | %-30s" "$_url"
  printf "\n"
}

##
# @brief traverse through all the submodules in the given intermediate repo(s)
##
function __status_traverse_table() {
  # go through all given intermediate repo arguments
  for _meta_repo in "$@"; do
    # ignore the non-interrepo flags
    chk_flag -hash $_meta_repo || chk_flag -url $_meta_repo && continue

    # fix repo_name (remove system prefix, add javis as prefix)
    local _prefix=$(get_suffix "$_meta_repo")
    _meta_repo="javis_$_prefix"

    # display submodule information as a column table print style
    text "$FG_LCYAN|--$_meta_repo--|"
    printf "%-50s | %-41s | %-60s " "--submodule--" "--branch--" "--status--"
    [[ $GL_STATUS_HASH == true ]] && printf " | %-40s" "--git hash--"
    [[ $GL_STATUS_URL == true ]]  && printf " | %-30s" "--git url--"

    # show the status for all recursive submodule
    printf "\n"
    pushd "$_meta_repo"
    traverse_submodules __status "$_meta_repo"
    printf "\n"
    popd

  done
}

# //////////////////////////////////////////////////////////////////////////////
# @brief git sync
# //////////////////////////////////////////////////////////////////////////////

##
# @brief syncs local repository to match remote
##
function __sync() {
  # printf colors
  local _pfred=$(tput setaf 1)
  local _pfblue=$(tput setaf 4)
  local _pfnormal=$(tput sgr0)

  # collect git submodule status information
  local _submodule=$(realpath --relative-to="$JAVIS_SRC_PATH" "$(pwd)")
  local _hash=$(git rev-parse --verify HEAD)  # get the current hash commit
  local _co=$(git symbolic-ref -q HEAD)       # get the current branch
  _co=${_co#"refs/heads/"}           # find the short branch name
  [ -z $_co ] && _co="-"                      # reset to detached head display symbol '-'

  printf "%-10s | %-30s | %-50s | %-50s \n" "...sync" "$_co" "$_hash" "$_submodule"
  git fetch -q -a

  # - resets hard all local branches to match remote branches
  # - removes all deleted branches

  # collect the local & remote branches
  local _heads=($(git_branches heads))
  local _remotes=($(git_branches remotes))

  # get the current checked out branch
  local _co=$(git symbolic-ref -q HEAD)
  # ignore current branch (if given as user argument)
  $GL_SYNC_IGNORE_CURR && _heads=( "${_heads[@]/$_co}" )

  # find the short branch name
  _co=${_co#"refs/heads/"}
  # go through all local branches and reset hard local branch to origin/remote
  for branch in "${_heads[@]}"; do
    branch=$( echo "$branch" | tr -d "\'")  # remove the single quotes from the branch string
    short=${branch#"refs/heads/"}           # find the short branch name

    # match the local & remote branches
    if val_in_arr "'refs/remotes/origin/$short'" "${_remotes[@]}"; then
      # reset the local branch to the remote
      git update-ref "$branch" "refs/remotes/origin/$short"
    else
      [ $GL_SYNC_DELETE_BRANCH = true ] && git branch -d $short
    fi
  done

  # go back to original commit hash
  if ! $GL_SYNC_IGNORE_CURR; then
    [ -z $_co ] && _co=$(git rev-parse --verify HEAD)  # co as hash commit, if co as detached head
    git checkout -q -f $_co
  fi
}

##
# @brief traverse over all submodules in the intermediate repos, apply the given function on _submodule
##
function __sync_traverse() {
  # go through all given intermediate repo arguments
  for _meta_repo in "$@"; do
    # ignore the non-interrepo flags
    chk_flag -hard $_meta_repo || chk_flag -del $_meta_repo && continue

    # fix repo_name (remove system prefix, add javis as prefix)
    local _prefix=$(get_suffix "$_meta_repo")
    _meta_repo="javis_$_prefix"

    # display submodule table header
    text "\n$FG_LCYAN|- -$_meta_repo--|$FG_DEFAULT"
    printf "%-10s | %-30s | %-50s | %-64s " "" "--branch--" "--status--" "--submodule--"
    printf "\n"

    # traverse over the intermeidate submodules & sync
    pushd "$_meta_repo"
    __sync                                    # sync meta repo
    traverse_submodules __sync  "$_meta_repo" # sync all recursive submodule repos
    popd

  done
}

# //////////////////////////////////////////////////////////////////////////////
# @brief: main entrypoint
# //////////////////////////////////////////////////////////////////////////////
pushd $JAVIS_SRC_PATH

# enable
chk_flag -p $@ && GL_OPTS="$GL_OPTS -p"
chk_flag -v $@ && GL_OPTS="$GL_OPTS -v"

if chk_flag status $@ ; then
  shift

  # append the status optional flags
  chk_flag -hash $@ && GL_STATUS_HASH=true
  chk_flag -url $@ && GL_STATUS_URL=true

  # display the status optional flags table header
  [[ $GL_STATUS_HASH == true ]] && printf " | %-40s" "--git hash--"
  [[ $GL_STATUS_URL == true ]]  && printf " | %-30s" "--git url--"

  __status_traverse_table $@

elif chk_flag sync $@ ; then
  shift

  # append the display options
  chk_flag -del $@ && GL_SYNC_DELETE_BRANCH=true
  chk_flag -hard $@ && GL_SYNC_IGNORE_CURR=false

  # show git status for all the given intermediate level repos
  __sync_traverse $@

fi

# cleanup & exit
exit_pop_success
