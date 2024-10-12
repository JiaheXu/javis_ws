##
# A header containing misc. variables and sources for the terraform scripts
# Joshua Spisak <joshs333@live.com> July 14, 2020
##
# Some directory variabls
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file_path="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__file_name="$(basename "${BASH_SOURCE[0]}")"
__call_dir="$(pwd)"


function pathadd() {
    if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
        export PATH="${PATH:+"$PATH:"}$1"
    fi
}

function command_exists() {
    which $1 > /dev/null
    return $?
}

function get_arg_val() {
    idx=$1

    if [[ -z $value ]]; then
        return 2
    fi
    tidx=0
    for var in "${@:2}"; do
        if [[ $tidx == $idx ]]; then
            echo $var
            return 0
        fi
        tidx=$((tidx+1))
    done
    return 1
}

##
# Find the index of a value in an array
##
function getidx() {
    val=$1

    if [[ -z $value ]]; then
        return 2
    fi
    tidx=0
    for var in "${@:2}"; do
        if [[ $var == $val ]]; then
            echo $tidx
            return 0
        fi
        tidx=$((tidx+1))
    done
    return 1
}

function yesno() {
    prompt=$1
    yn_def=$(echo "$2" | tr '[:upper:]' '[:lower:]')
    def_res=""

    if [[ ${yn_def:0:1} == "y" ]]; then
        suggestion="Y/n"
        def_res=0
    elif [[ ${yn_def:0:1} == "n" ]]; then
        suggestion="y/N"
        def_res=1
    else
        yn_def=""
        suggestion="y/n"
    fi
    valid=false
    count=3
    while [[ $valid == false ]] && (( $count > 0 )); do
        read -p "$prompt [$suggestion]: " result
        result=$(echo "$result" | tr '[:upper:]' '[:lower:]')
        mess=""
        if [[ $result == "" ]]; then
            if [[ $yn_def == "" ]]; then
                mess="No default. Please enter 'y' or 'n'"
            else
                return $((def_res))
            fi
        elif [[ ${result:0:1} == "y" ]]; then
            return 0
        elif [[ ${result:0:1} == "n" ]]; then
            return 1
        else
            mess="Invalid entry: [$result]"
        fi
        count=$((count - 1))
        echo "$mess ($count more tries left)"
    done
    exit 1
}

function read_text() {
    prompt=$1
    default=$2

    suggestion=""
    if [[ ! -z $default ]]; then
        suggestion=" [$default]"
    fi

    valid=false
    count=3
    while [[ $valid == false ]] && (( $count > 0 )); do
        read -p "${prompt}${suggestion}: " result
        mess=""
        if [[ $result == "" ]]; then
            if [[ $default == "" ]]; then
                mess="No default. Please provide input."
            else
                echo $default
                return 0
            fi
        else
            echo $result
            return 0
        fi
        count=$((count - 1))
        echo "$mess ($count more tries left)"
    done
    exit 1
}


##
# Checks arguments to make sure they exist and are equal
# $1: value the arg should be
# $2: value to check against (can be empty)
# Returns 0 if $1 == $2, otherwise 1 if != or 2 if -z $2
#
# Usage: "if chk_arg yes $1; then ..."
function chk_arg() {
    value=$1
    check=$2

    if [[ -z $check ]]; then
        return 2
    fi
    if [[ $value == $check ]]; then
        return 0
    else
        return 1
    fi
}

##
# Checks arguments to make sure they exist and are equal
# $1: flag to check for arguments to contain
# $>1: arguments to check against
# Returns 0 if $1 matches anything $>1, returns 1 if no matches, 2 if $1 is empty
#
# Usage: "if chk_flag -y $@; then ..."
function chk_flag() {
    value=$1

    if [[ -z $value ]]; then
        return 2
    fi
    for var in "${@:2}"; do
        if [[ $value == $var ]]; then
            return 0
        fi
    done
    return 1
}

# A function that returns the argument provided
function return_num() {
    if [[ -z $1 ]]; then
        return 0
    fi
    return $1
}

# Usage: if last_command_failed; then ...
function last_command_failed() {
    [[ $? == 0 ]] || return 0
    return 1
}

# Usage: if last_command_succeeded; then ...
function last_command_succeeded() {
    [[ $? == 0 ]] && return 0
    return 1
}

##
# Exit with success code
##
function exit_success() {
    newline;
    exit 0;
}

##
# Exit with failure code
##
function exit_failure() {
    newline;
    exit 1;
}

##
# Exit success, pop directory on stack
##
function exit_pop_success() {
    popd
    exit_success
}

##
# Exit error, pop directory on stack
##
function exit_pop_error() {
    error $1
    popd
    exit_failure
}

##
# Saves the given directory at the top of the directory stack, then cd to directory
# - stack standard output silenced
##
function pushd () {
    command pushd "$@" > /dev/null;
}

##
# Removes the top directory from the stack, then cd to directory
# - stack standard output silenced
##
function popd () {
    command popd "$@" > /dev/null;
}

##
# Check if given value is set
##
function is_empty() {
    [[ -n "$1" ]] && return 1   # non-empty value
    return 0                    # empty value
}

##
# Check if file exists
##
function file_exists() {
    [[ -f $1 ]] && return 0
    return 1
}

##
# Trap control-c
##
function ctrl_c() {
    exit_success
}

##
# Write a given string to a given output file
# :param file: given output file
# :param str: given string
##
function write() {
    # write string ($2) to file ($1)
    echo $2 >> $1
}

##
# Check if file exists
#
function file_exists() {
    local filename=$1
    [[ -f $filename ]] || [[ -L $filename ]] && return 0
    return 1
}

#
# Check if directory exists
#
function dir_exists() {
    local direname=$1
    [[ -d $direname ]] && return 0
    return 1
}

##
# Removes a file from disk
##
function rm_file() {
    # remove the rc and the configuration files
    if file_exists $1; then
        rm $1
    fi
}

##
# Removes a file from disk
##
function rm_dir() {
    # remove the rc and the configuration files
    if dir_exists $1; then
        rmdir $1
    fi
}

##
# Entrypoint main warpper, creates title and traps ctrl-c
##
function main() {
  title " \n\n == ${@} == \n\n"

  # trap ctrl-c and call ctrl_c
  trap ctrl_c INT
}

##
# Remove leading and trailing whitespaces from given string
##
function trim_whitespace() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    printf '%s' "$var"
}

##
# Find the index of a value in an array
##
function get_idx() {
    val=$1

    if [[ -z $value ]]; then
        return 2
    fi
    tidx=0
    for var in "${@:2}"; do
        if [[ $var == $val ]]; then
            echo $tidx
            return 0
        fi
        tidx=$((tidx+1))
    done
    return 1
}

##
# Checks if given value is found in array
#   - reference: https://stackoverflow.com/a/8574392/3554704
##
function get_value() {
    local iter value="$1"
    # shift the first argument, to only have the list-values as the arguments
    shift
    # for without in, iterates over the given arguements
    for iter; do [[ "$iter" == "$value" ]] && return 0; done
    return 1
}

##
# Checks that the nth positional argument is the given value
# $1: nth position of argument
# $2: value argument to check as
# $>2: given arguments to check against
# Returns 0 if check is valid, otherwise some error exit code
##
function chk_nth_flag() {
    n=$1 value=$2
    shift 2
    check=${@:$n:1}
    # check if check input exists
    if [[ -z $value ]]; then
        return 5  # input/output error
    fi
    if [[ $value == $check ]]; then
        return 0
    else
        return 1
    fi
}

##
# Get the prefix of string, deliminated by '_'
##
function get_prefix() {
    echo "${$1%%.*}"
}

##
# Remove the prefix of string, deliminated by '_'
##
function rm_prefix() {
    local str="$1" pre="$2" str=${str#"$pre"}
    echo "${str}"
}

##
# get the suffix of string, deliminated by '_'
##
function get_suffix() {
    local _str=$1
    echo "${_str##*.}"
}

##
# Remove the suffix of string, deliminated by '_'
##
function rm_suffix() {
    local str="$1" suf="$2"
    str=${str%"$suf"}
    echo "${str}"
}

##
# Checks if given value is found in array
#   - reference: https://stackoverflow.com/a/8574392/3554704
##
function in_arr() {
  local iter value="$1"
  # shift the first argument, to only have the list-values as the arguments
  shift
  # for without in, iterates over the given arguements
  for iter; do [[ "$iter" == "$value" ]] && return 0; done
  return 1
}

##
# Check if given value is set
##
function is_empty() {
    local value=$1
    # non-empty value
    [[ -n "$value" ]] && return 1
    # empty value
    return 0
}

##
# Check if file exists
##
function file_exists() {
    local filename=$1
    [[ -f $filename ]] && return 0
    return 1
}

##
# Find the index of a value in an array
##
function arr_idx() {
    # defined iteration variables
    local count=0 iter value="$1"
    shift
    # for without in, iterates over the given arguements
    for iter; do
      ((count++))
      [[ "$iter" == "$value" ]] && echo $count && return 0;
    done
    echo -1
}

##
# returns the argument value of a given flag
# $1 flag associated with argument value
# $@ array of all given arguments
##
function get_arg() {
    local _flag=$1
    shift
    # get the index of the flag
    idx=$(arr_idx $_flag $@)
    # missing flag, return empty value
    [ $idx == -1 ] && echo "" && return 0
    # increase counter, argment is always next value
    ((idx++))
    # return the argument value
    arg=${@:$idx:1}
    echo $arg
}

##
# Find the index of a value in an array
##
function idx() {
    local iter value="$1"
    shift
    # for without in, iterates over the given arguements
    for iter; do
        [[ "$iter" == "$value" ]] && echo $((count++)) && return 0;
    done
    echo -1
}
