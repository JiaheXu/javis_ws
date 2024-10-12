# Deployer

Deployer serves the purpose of automating deployment, management and operations of containerized (or non-containerized) applications across different hosts.

# Install Dependencies

    sudo apt-get update
    sudo apt install -y --no-install-recommends python2.7 python-setuptools python-pip
    pip2 install wheel --user
    pip2 install setuptools PyYAML pexpect --user

# Clone Deployer Workspace

    mkdir ~/deployer/
    cd ~/deployer/
    git clone git@bitbucket.org:cmusubt/deployer.git src
    cd src
    git checkout develop

# Setup Deployer Environment

Please setup a few environment variables in your `~/.bashrc`

    # export the deployer's top level path
    export DEPLOYER_PATH=$(pwd)

    # export the deployer books path
    export DEPLOYER_BOOKS_PATH=/path/to/deploybooks/

    # export the deployer scripts path
    export DEPLOYER_SCRIPTS=$(pwd)/bin/

    # export the autocompletion path
    # - leave filepath blank, if autocompletion is not added
    export DEPLOYER_EXPORT_FILEPATH=$(pwd)/some/path/to/autocompletion/

    # export the bashrc path
    export DEPLOYER_BASHRC_FILEPATH=.bashrc

    # export the number of parallel jobs, for matching sections
    export DEPLOYER_PARALLELIZE_MATCHES_JOBS=2

    # export the workspace name, the deployer is being used by
    export DEPLOYER_WS_NAME=foo_ws

    # add deployer bin script to PATH
    export PATH=$PATH:$DEPLOYER_SCRIPTS

These environment setup steps can be automated using a workspace script.

# Tutorials

Please make sure, you have setup your environment variables.

## Tutorial 1: Simple Section

    # run an example tutorial
    python bin/deployer -s hello_world

This section `hello_world` is associated with the yaml:

- `src/tutorials/example1.yaml`

You will see, deployer matched the two sections:

    hello_world
        -> hello_world.hello
        -> hello_world.goodbye

Please open the `example1.yaml` and investigate the exact commands that are run.

## Tutorial 2: Extended Sections

    # run an extended yaml file
    python bin/deployer -s test.extended.foo

This section `test.extended.foo` is associated (and extended) with the yamls:

- `src/tutorials/example2.yaml`
- `src/tutorials/subdirectory/extended.yaml`

## Tutorial 3: Regex Matcher

    # run an extended yaml file
    python bin/deployer -s test.foo

This section `test.foo` is associated (and extended) with the yamls:

- `src/tutorials/example2.yaml`
- `src/tutorials/subdirectory/extended.yaml`

It is the same as **Tutorial 2**, except we can pass a shorter section name. The regex matcher
will match the longest matched section name.

## Tutorial 4: Preview and Verbose

    # run an example tutorial
    python bin/deployer -s hello_world -p -v

The deployer will only preview and not run anything when passed the preview (`-p`) flag.
The deployer will show the details of which commands (in order) will be run when passed the verbose (`-v`) flag.


## Author

Katarina Cujic
