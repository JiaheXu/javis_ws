# Workspaces

The mmpug workspaces are found in the following directories:

    ~/mmpug_ws/src  ->

        # autonomy, planning, controls
        mmpug_autonomy

        # common libraries such as communication manager, shared ros messages, utilities, etc.
        mmpug_common

        # payload sensor hardware drivers
        mmpug_drivers

        # state estimation, currently configured to use LOAM
        mmpug_estimation

        # simulation, sensor simulators, visualization setup
        mmpug_sim
    
    ~/mmpug_ws/operations ->
        # Various tools and scripts for setup and installation of workspace
        mmpug_ansible

        # Various configuration for deployment
        mmpug_deploy

        # Docker compose and dockerfiles
        mmpug_docker

        # Various scripts to help with deployment (using configuration in mmpug_config)
        mmpug_utils

        # Sets the version of docker in mmpug_docker
        .version.env


# Connect To Azure Account

The docker images can be stored on azure rather than built whenever there are updates.

You will need to have an Azure account to access the azure docker registry of where we store docker images.

Connect to Azure docker registry, from the basestation:

        # az login will prompt a browser window. Enter your user credentials to login.
        az login

        # login to the mmpug docker registry
        az acr login --name mmpug
