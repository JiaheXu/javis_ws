# Localhost or Basestation

## Step 1a: Pull Docker Images From Azure

    # pull a group of workspaces' docker image
    javis deployer local.docker.registry.pull

    # (Optional)
    # Pull a specific workspace docker image  (for example the common docker image)
    javis deployer local.common.docker.registry.pull

    # remove all containers (so that we remove any references to previous images)
    javis deployer local.docker.stop
    javis deployer local.docker.rm

    javis deployer pt002.docker.make

## Step 1b (Optional): Build Docker Images

    **If you don't have azure set up**
    You can just make the docker images from script. Often this is also recommended if doing development.

    # Build a docker image (example, common docker image)
    javis deployer local.common.docker.make

## Step 2: Create Docker Containers

    # create all the local docker containers 
    deployer -s local.start

    # (Optional)
    # Create a specific workspace's docker container (for example the common docker container)
    deployer -s local.{$docker}.start

    # (Optional)
    # Stop all local docker containers
    deployer -s local.{$docker}.stop

    # (Optional)
    # Remove all local {$docker} containers
    deployer -s local.{$docker}.rm

    ## {$docker} can be one of {common autonomy drivers estimation sim}
    
## Step 3: Catkin Build

    # build all the catkin workspaces (already pre-configured to build inside its respective docker containers)
    deployer -s local.core.build

    # (Optional)
    # build a specific catkin workspace (already pre-configured to build inside its respective docker containers)
    deployer -s local.common.build

- you must always have a started docker container before you can catkin build (refer to step 3).

## Step 4: Enter the Container

    # view all running docker containers
    docker ps

    # enter a running docker container
    docker-join.bash -n [container name]

    # ... do some development

    # exit the container
    exit

Once you are inside the container, you can manually launch or even manually catkin rebuild packages.

## Comments
If you are trying to run on a remote payload, substitute local for a target payload: eg: javis deployer pt002.docker.make
