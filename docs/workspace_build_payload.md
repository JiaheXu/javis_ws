# Remote Payload

**Deploying to remote robot PT-002 (example), via the basestaion laptop**

When are running the `mmpug deployer [robot]` commands on the basestation, the deployer commands will ssh into the remote system and run the actual deployer commands on the actual remote.

## Step 1: Pull Docker Images From Azure

    # pull a group of workspaces' docker image on the remote system
    mmpug deployer pt002.docker.registry.pull

    # (Optional)
    # Pull a specific workspace docker image on the remote system (for example the common docker image)
    mmpug deployer pt002.common.docker.registry.pull

    # remove all containers (so that we remove any references to previous images)
    mmpug deployer pt002.docker.stop
    mmpug deployer pt002.docker.rm

    **If you don't have azure set up**
    You can just make the docker images from script. Often this is also recommended if doing development.
    mmpug deployer pt002.docker.make

## Step 3: Create Docker Containers

    # create all the docker containers on the remote system
    mmpug deployer pt002.docker.shell.start

    # (Optional)
    # Create a specific workspace's docker container on the remote system(for example the common docker container)
    mmpug deployer pt002.common.docker.shell.start

    # (Optional)
    # Stop all pt002 docker containers on the remote system
    mmpug deployer pt002.docker.shell.stop

    # (Optional)
    # Remove all pt002 docker containers on the remote system
    mmpug deployer pt002.docker.shell.rm

## Step 4: Transfer Workspace To Remote System

    # transfer all the code from localhost ~/mmpug_ws to the remote system (will be transfered to the same ~/mmpug_ws path).
    mmpug deployer pt002.transfer.to

    # faster transfer   -- does not copy over .git, so your remote system 'git' commands will be inaccurate
    #                   -- you can get back the proper .git on the remote, by calling the above '.transfer' deployer call
    mmpug deployer pt002.skel_t.to

## Step 5: Catkin Build

    # build all the catkin workspaces (already pre-configured to build inside its respective docker containers)
    mmpug deployer pt002.catkin.build

    # (Optional)
    # build a specific catkin workspace (already pre-configured to build inside its respective docker containers)
    mmpug deployer pt002.common.catkin.build

- you must always have a started docker container before you can catkin build (refer to step 3).

## Step 6: Enter the Container

    # connect to remote system
    ssh mmpug-pt-002

    # view all running docker containers
    docker ps

    # enter a running docker container
    docker-join.bash -n [container name]

    # ... do some development

    # exit the container
    exit

Once you are inside the container, you can manually launch or even manually catkin rebuild packages.
