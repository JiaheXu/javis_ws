# Change text colors
# Thanks: https://misc.flogisoft.com/bash/tip_colors_and_formatting
FG_DEFAULT="\e[39m"
FG_BLACK="\e[30m"
FG_RED="\e[31m"
FG_GREEN="\e[32m"
FG_YELLOW="\e[33m"
FG_BLUE="\e[34m"
FG_MAGENTA="\e[35m"
FG_CYAN="\e[36m"
FG_LGRAY="\e[37m"
FG_DGRAY="\e[90m"
FG_LRED="\e[91m"
FG_LGREEN="\e[92m"
FG_LYELLOW="\e[93m"
FG_LBLUE="\e[94m"
FG_LMAGENTA="\e[95m"
FG_LCYAN="\e[96m"
FG_LWHITE="\e[97m"

FG_COLOR_TITLE="${FG_BLUE}"
FG_COLOR_SUBTITLE="${FG_GREEN}"
FG_COLOR_TEXT="${FG_DEFAULT}"
FG_COLOR_DEBUG="${FG_LGRAY}"
FG_COLOR_ERROR="${FG_RED}"
FG_COLOR_WARNING="${FG_YELLOW}"

DISABLE_TITLE=0
DISABLE_TEXT=0
DISABLE_DEBUG=0
DISABLE_ERROR=0
DISABLE_WARNING=0

# global text color
GL_TEXT_COLOR=${FG_DEFAULT}

##
# Writes out a colored title
function title() {
    if [[ $DISABLE_TITLE == 1 ]]; then
        return
    fi
    echo -e "${FG_COLOR_TITLE}${@}${FG_DEFAULT}"
}

##
# Writes out a colored subtitle
function subtitle() {
    if [[ $DISABLE_TITLE == 1 ]]; then
        return
    fi
    echo -e "${FG_COLOR_SUBTITLE}${@}${FG_DEFAULT}"
}

##
# Writes out colored text
function text() {
    if [[ $DISABLE_TEXT == 1 ]]; then
        return
    fi
    echo -e "${FG_COLOR_TEXT}${@}${FG_DEFAULT}"
}

##
# Writes out colored debug messages
function debug() {
    if [[ $DISABLE_DEBUG == 1 ]]; then
        return
    fi
    echo -e "${FG_COLOR_DEBUG}${@}${FG_DEFAULT}"
}

##
# Writes out colored error messages
function error() {
    if [[ $DISABLE_ERROR == 1 ]]; then
        return
    fi
    echo -e "${FG_COLOR_ERROR}${@}${FG_DEFAULT}"
}

##
# Writes out colored warning messages
function warning() {
  if [[ $DISABLE_WARNING == 1 ]]; then
    return
  fi
  echo -e "${FG_COLOR_WARNING}${@}${FG_DEFAULT}"
}

##
# Writes out a set colored message
function text_color() {
    echo -e "${GL_TEXT_COLOR}${@}${FG_DEFAULT}"
}

##
# Decodes a url
# urldecode <string>
# Thanks: https://gist.github.com/cdown/1163649
function urldecode() {
    local url_encoded="${1//+/ }"
    printf '%b' "${url_encoded//%/\\x}"
}

##
# Creates a newline
function newline() {
    echo -e "\n";
}

