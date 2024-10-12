#!/usr/bin/env bash
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
eval "$(cat $__dir/operations/javis_utils/scripts/header.sh)"
eval "$(cat $__dir/operations/javis_utils/scripts/formatters.sh)"

FILENAME=$__file_name
# Global install message
export JAVIS_GLOBAL_VERSION=2
# JAVIS Install Message
export JAVIS_MAJOR_EPOCH=1
# MMPUg Install --min message
export JAVIS_MAJOR_VERSION=2
# Mark upgrades - but no new install needed
export JAVIS_MINOR_VERSION=1
# If there is a new maintainer please update :)
export JAVIS_MAINTAINER="Joshua Spisak <jspisak@andrew.cmu.edu>"

if [[ $EUID == 0 ]] && [[ ! $JAVIS_FORCE_ROOT == true ]]; then
    echo "Do not run this script as root (set JAVIS_FORCE_ROOT=true to override)"
    exit
fi

###############################################################################
# Initial set of exports needed by stack
###############################################################################
export JAVIS_GLOBAL_CONF=/etc/javis/javis.conf

# == JAVIS Configuration ==
# -- General Paths --
# NOTE TO MAINTAINER - be careful to make sure these align with ansible
export JAVIS_PATH=$(realpath $__dir)
export JAVIS_SRC_PATH=$JAVIS_PATH/src
export JAVIS_OPERATIONS=$JAVIS_PATH/operations
export JAVIS_DOCKER_PATH=$JAVIS_PATH/operations/javis_docker
export JAVIS_DEPLOY_CONF=$HOME/.javis/auto/deploy.conf
export JAVIS_INSTALL_CONF=$HOME/.javis/auto/install.conf

# -- Script Paths --
export JAVIS_DOCKER_SCRIPTS=$JAVIS_PATH/operations/javis_docker/scripts
export JAVIS_ANSIBLE_SCRIPTS=$JAVIS_PATH/operations/javis_ansible/scripts
export DEPLOYER_SCRIPTS=$JAVIS_PATH/operations/javis_utils/deployer/bin
export JAVIS_UTILS_SCRIPTS=$JAVIS_PATH/operations/javis_utils/scripts

# == Deployer Configuration ==
# -- General Paths --
export DEPLOYER_PATH=$JAVIS_PATH/operations/javis_utils/deployer/
export DEPLOYER_EXPORT_FILEPATH=$HOME/.javis/auto/completion
export DEPLOYER_BASHRC_FILEPATH=.javis/auto/javis_redirect.bash
export DEPLOYER_WS_NAME=javis_ws

# Set the deployer's books path
export DEPLOYER_BOOKS_PATH=$JAVIS_PATH/operations/javis_deploy/books/main/
export DEPLOYER_BOOKS_EXTEND_PATH=$JAVIS_PATH/operations/javis_deploy/books/

# Set to the number of parallelized cores to run deployer matches
if [ -z $GL_DEPLOYER_PARALLELIZE_MATCHES_JOBS ]; then
    export DEPLOYER_PARALLELIZE_MATCHES_JOBS=2
else
    export DEPLOYER_PARALLELIZE_MATCHES_JOBS=$DEPLOYER_PARALLELIZE_MATCHES_JOBS
fi

export JAVIS_USERID=$(id -u)
export JAVIS_GROUPID=$(id -g)


alias javis-cd="cd $JAVIS_PATH"
alias javis-export="source javis-export-ros"
alias dump-frames="python2 /opt/ros/melodic/lib/tf/view_frames"

# -- Append to PATH --
pathadd $JAVIS_PATH
pathadd $JAVIS_DOCKER_SCRIPTS
pathadd $JAVIS_ANSIBLE_SCRIPTS
pathadd $DEPLOYER_SCRIPTS
pathadd $JAVIS_UTILS_SCRIPTS

###############################################################################
# Check if things are installed / give warnings if they are not
###############################################################################
function run_checks() {
    if [ -e $HOME/.javis/auto ]; then
        echo "source $JAVIS_PATH/$FILENAME" > $HOME/$DEPLOYER_BASHRC_FILEPATH

        mkdir -p $DEPLOYER_EXPORT_FILEPATH

        if [ ! -e $DEPLOYER_EXPORT_FILEPATH/deployer.cmpl ] || [ ! -e /tmp/javis_deployer_genned ]; then
            if command_exists deployer; then
                touch /tmp/javis_deployer_genned
                cd $DEPLOYER_PATH
                deployer -a --export deployer -f .javis
                cd $__call_dir
            fi
        fi
    else
        echo "WARN: javis rc folder does not exist, please run 'javis install'"
        echo "      autocompletion might not work correctly"
        echo
    fi

    if [ -e $JAVIS_DEPLOY_CONF ]; then
        source $JAVIS_DEPLOY_CONF > /dev/null || echo "source failed :(" > /dev/null
    else
        echo "WARN: Deploy configuration not found, please run 'javis install'"
        echo "      docker might not work correctly"
        echo
    fi


    if ! command_exists deployer; then
        echo "WARN: deployer not installed, please run 'javis install'"
        echo
    fi

    if ! command_exists ansible; then
        echo "WARN: ansible not installed, please run 'javis install'"
        echo
    fi


    if [ -e $JAVIS_INSTALL_CONF ]; then
        source $JAVIS_INSTALL_CONF

        if [ "$INSTALL_JAVIS_MAJOR_EPOCH" != "$JAVIS_MAJOR_EPOCH" ]; then
            echo "Script version $JAVIS_MAJOR_EPOCH.$JAVIS_MAJOR_VERSION.$JAVIS_MINOR_VERSION"
            echo "Installed version $INSTALL_JAVIS_MAJOR_EPOCH.$INSTALL_JAVIS_MAJOR_VERSION.$INSTALL_JAVIS_MINOR_VERSION"
            echo "Running 'javis install' recommended"
        elif [ $INSTALL_JAVIS_MAJOR_VERSION != $JAVIS_MAJOR_VERSION ]; then
            echo "Script version $JAVIS_MAJOR_EPOCH.$JAVIS_MAJOR_VERSION.$JAVIS_MINOR_VERSION"
            echo "Installed version $INSTALL_JAVIS_MAJOR_EPOCH.$INSTALL_JAVIS_MAJOR_VERSION.$INSTALL_JAVIS_MINOR_VERSION"
            echo "Running 'javis install --min' recommended"
        fi
    else
        echo "WARN: Deploy configuration not found, please run javis install"
        echo "      unable to check install version to determine if install is needed"
    fi

    if command_exists nvidia-smi && [ -z $JAVIS_DISABLE_GPU_CHECK ]; then
        if [[ $JAVIS_HOST_TYPE == *"non-gpu" ]]; then
            echo "WARN: GPU Detected but host type does not have a GPU? You might need to run 'javis install --global'"
            echo
            echo "(Disable this message by setting the environment variable JAVIS_DISABLE_GPU_CHECK)"
        fi
    fi

    if [ -e $JAVIS_GLOBAL_CONF ]; then
        source $JAVIS_GLOBAL_CONF
        if [[ $JAVIS_INSTALL_GLOBAL_VERSION != $JAVIS_GLOBAL_VERSION ]]; then
            echo "Script global version $JAVIS_GLOBAL_VERSION"
            echo "Installed global version $JAVIS_INSTALL_GLOBAL_VERSION"
            echo "Running 'javis install --global' recommended"
            echo
        fi
    fi
}

###############################################################################
# Installation functions
###############################################################################
function create_desktop_icons {
    # remove previous desktop icons
    python $JAVIS_OPERATIONS/javis_utils/scripts/generate_desktop_icons.py --yaml $JAVIS_OPERATIONS/javis_deploy/desktop_icons/.templates/config.yaml --clean
    # create new desktop icons
    python $JAVIS_OPERATIONS/javis_utils/scripts/generate_desktop_icons.py --yaml $JAVIS_OPERATIONS/javis_deploy/desktop_icons/.templates/config.yaml
}

function install_config {
    mkdir -p ~/.javis

    echo "Creating config...."
    sudo /bin/bash -c "echo \"source $JAVIS_PATH/$FILENAME\" > $HOME/$DEPLOYER_BASHRC_FILEPATH"

    sed -i "/JAVIS SOURCE REDIRECT/d" ~/.bashrc
    echo "source \"$HOME/$DEPLOYER_BASHRC_FILEPATH\" # JAVIS SOURCE REDIRECT" >> ~/.bashrc
    echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/lib/aarch64-linux-gnu/tegra" >> ~/.bashrc
    cat ~/.bashrc
}

function install_py_scripts {
    if [ -e $JAVIS_OPERATIONS/javis_utils/host_info_tools/src ]; then
        cd $JAVIS_OPERATIONS/javis_utils/host_info_tools
        sudo -H python3 -m pip install .
        sudo git clean -xfd 2> /dev/null
    else
        echo "WARN: host_info_tools src directory does not exist, please clone operations submodules."
    fi

    # clone all operation submodules
    if [ ! -e $DEPLOYER_SCRIPTS ]; then
        echo "WARN: deployer bin directory does not exist, please clone operations submodules."
        return
    fi

    # install python scripts
    cd $DEPLOYER_PATH
    python setup.py install --user
    # validate python installed deployer
    if last_command_failed; then
        "deploy builder install failed."
        cd $__call_dir
        exit 1
    fi
    git clean -f -d
    cd $__call_dir

    echo "finished"
}

###############################################################################
# Process command line options if necessary
###############################################################################
if [[ $# > 0 ]]; then
    keyword=$1

    if [ $keyword == "-h" ] || [ $keyword == "--help" ]; then
        echo "$FILENAME"
        echo "Usage:"
        echo "  Source to set paths to use the javis workspace."
        echo "      eg: source $FILENAME"
        echo "  Use as command line tool to setup the workspace."
        echo "      eg: $FILENAME <keyword>"
        echo ""
        echo "Keywords:"
        echo "  -h, --help          show this help message"
        echo "  --icons             used to update the desktop icons folder"
        echo ""
        echo "Contact $JAVIS_MAINTAINER for help :)"
    elif [ $keyword == "--docker-setup" ]; then
        mkdir -p ~/.javis/auto
        install_config
        install_py_scripts
    elif [ $keyword == "--icons" ]; then
        create_desktop_icons
    else
        echo "Unknown keyword: '$keyword', consider using the keyword '-h' or '--help' :)"
        echo "If you are trying to install the workspace, try using javis install -h"
    fi
    exit 0
fi


source $JAVIS_PATH/operations/.version.env
if [ -z $JAVIS_SETUP_SUPPRESS_CHECKS ]; then
    run_checks
elif [ -e $JAVIS_DEPLOY_CONF ]; then
    source $JAVIS_DEPLOY_CONF
fi
# If we are sourcing, source all the automation tools
source $JAVIS_PATH/operations/javis_deploy/automate/javis
