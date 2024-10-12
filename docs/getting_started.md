# Getting Started

The JAVIS projects uses a few tools for development and deployment. Check [tooling documentation](tooling_documentation.md) for links to documentation on these toolsets.

If you are going to be deploying to the robots directly from your machine (performing `javis install --global` in the instructions below). Make sure your computer hostname is unique and identifiable (please do not install to deploy if you have a generic hostname).

If you want to change your hostname please follow the instructions [here](https://www.cyberciti.biz/faq/ubuntu-change-hostname-command/)

## 0.prerequisite

        sudo chown -R javis:javis /external # only for new payloads
        
        sudo apt-get update -y
        sudo apt upgrade -y
        sudo apt-get install -y libgtk-3-dev apt-utils libgtk-3-dev python3-pip openssh-server chrony
        sudo pip install pyopenssl wheel PyYAML pexpect python-dotenv
        sudo pip3 install wheel setuptools shyaml psutil rospkg jinja2==3.0.3
        
## 1. Bitbucket SSH Keys

**Create SSH keys on localhost**

- Running the `javis install` should create a new ssh key at `~/.ssh/bitbucket.pub` if one does not already exist. We recommend you add this ssh key to your bitbucket [how-to here](https://support.atlassian.com/bitbucket-cloud/docs/set-up-an-ssh-key/).

## 2. Clone The JAVIS UGV Meta Repository  and Submodules

Clone the JAVIS Meta Repo

        cd ~
        git clone git@bitbucket.org:castacks/javis_ugv.git javis_ws
        cd javis_ws
        git checkout develop

Most of the workspaces is setup as `git submodules'. Git submodules have their own 'git' commands for how to clone them.

By default, the git submodules do not clone. You will have to explicitly clone the submodules:

        # go to the top-level javis meta repo path
        cd ~/javis_ws/

        # clone the submodules
        git submodule update --init --recursive operations
        git submodule update --init --recursive src/javis_autonomy
        git submodule update --init --recursive src/javis_common
        git submodule update --init --recursive src/javis_drivers
        git submodule update --init --recursive src/javis_sim
        git submodule update --init --recursive src/javis_estimation

Clone each folder separately unless you have access to [super_odometry](src/javis_estimation/super_odometry]). If you trying to init all submodules without having access to super odometry you will mess up your setup. Access to super odometry and other SLAM algorithms are granted separately from the main repos.

Anytime there is an update, you can perform the `submodule update` to pull the recent changes.

For more extensive documention on submodules see [here](https://git-scm.com/book/en/v2/Git-Tools-Submodules).


## 3. JAVIS Operations Installer

        # go to the top-level javis meta repo path
        cd ~/javis_ws/

        # Source workspace (once workspace is installed you wont need to do this)
        source ./javis-setup.bash

        # The first time you run it please make sure to install the following
        sudo apt install openssh-server

        # Install the workspace
        # NOTE: When it prompts for passwords it is asking for the same as your user password
        javis install

        # (Optional) Install the tools needed for deployment to payloads
        # do this if you want to use your laptop as a basestation
        # This will prompt a few different options, for the most part you
        # should just use the defaults.
        #
        # For the System ID (first option), make sure the System ID is ROS
        # safe (only alphanumeric characters, forward slashes, and underscores)
        # Also make sure the System ID contains the word 'base' so the communication
        # manager identifies it as a basestation.
        javis install --global

Generally you won't need to re-run the installer, javis-setup.bash will see whether or not an installer needs run again and give you an alert when it is sourced in the zsh or bashrc.

## 4. Restart your computer

You will need to restart your computer for the ansible changes to take effect.

## 5. Initial Build

After everything is installed you will probably want to build the full workspace, here are the instructions to do so.

        # If this command generates errors about needing to javis install
        # then the install was not successfully completed, try `javis install` again
        # and contact the maintainer if issues persist
        source ~/.bashrc

        # This will build the docker containers
        javis deployer local.make

        # This will start the docker containers
        javis deployer local.start

        # This will build all the workspaces
        javis deployer local.core.build

## 6. Verify Installations (Optional)

If you performed the install with ansible, ansible should be able to verify installations for you. But if something seems to be going wrong this is a good place to debug.

Verify you have all the operations tools installed correctly:

        # verify docker
        docker --version

        # verify docker works without sudo
        docker ps

        # verify docker-compose
        docker-compose -v

        # (optional) verify nvidia-docker
        nvidia-docker -v

        # verify ansible configuration management tools
        ansible --version

        # verify azure cli
        az --help

        # verify deployer script shows the help usage message
        deployer --help

- Notify the maintainer if any of the `help` usage messages do not show up.
