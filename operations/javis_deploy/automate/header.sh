# globals
GL_CMPL_DIR=$JAVIS_OPERATIONS/javis_deploy/automate/

# @brief get all the submodules in the current directory
function __get_all_submodules() {
  echo $(git config --file $JAVIS_PATH/.gitmodules --get-regexp path | awk '{ print $2 }')
}

# @brief traverse through all the submodules in the given source directory -- not recursive
function traverse_submodules() {
  # find all the submodules in the current path level
  local _sub=$(__get_all_submodules)
  local _funptr=$1
  local _meta_repo_name=$2

  # recursive traverse for found submodules
  for _sub in $_sub; do

    # ignore submodules not found in the target meta repo
    [[ ! "$_sub" =~ "src/$_meta_repo_name" ]] && continue
    _sub="$JAVIS_PATH/$_sub"

    # flat traversal -- not recursive
    if [ -d "$_sub" ]; then
      pushd "$_sub"   # cd to the submodule directory
      ($_funptr)      # execute function
      popd  # return to the previous current directory (before recursive traversal)
    fi
  done
}

# @brief returns "*" if the current git branch is dirty.
function git_is_dirty() {
  [[ $(git diff --shortstat 2> /dev/null | tail -n1) != "" ]] && echo "*"
}

# @brief returns number of untracked files
function git_ntracked() {
  expr `git status --porcelain 2>/dev/null| grep "^??" | wc -l`
}

# @brief returns number of uncommitted files
function git_ncommit() {
  expr $(git status --porcelain 2>/dev/null| egrep "^(M| M)" | wc -l)
}

# gets the list of branches
function git_branches(){
  echo "$(git for-each-ref --shell --format="%(refname)" refs/$1/)"
}
