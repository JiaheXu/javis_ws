# Host Management
The javis tools provide a set of tools to manage and interact with different hosts. These will only work if you have installed the deployment setup (eg: run `javis install --global`)

Specifically the `javis-hosts` tool (aliased to `javis hosts`). There is also a host-info-tools package that comes with it's command line tool `hit`.

## List JAVIS Hosts
Running `javis hosts` with no arguments by default just lists the detected javis hosts. You can also do `javis hosts list`

## Adopt JAVIS Hosts
Adopting a host is the process by which SSH keys and docker contexts and launch icons are generated. When you do `javis hosts list` it should give you up to two lists. One should be `Adopted JAVIS Hosts` and the other should be `Available JAVIS Hosts`.

To adopt a host take the Hostname of a host in `Available JAVIS Hosts`, and run `javis hosts adopt <hostname>`. This will ask you to enter the password of the javis host you are trying to adopt.

Once a host is adopted you can ssh to it without needing to enter a password. Eg: `ssh <hostname>` or `ssh <system alias>` will work.

## Issues?
The host-info-tools package is what facilitates this automatic host detection. It uses multi-cast to allow all hosts to see each other. When a host sees another it also requests a list of system parameters. These system parameters are things like system id, system component, etc.

    # To see your computers params
    hit params

If you don't see a host on the `javis hosts list` that you think should be present you can use `hit` to list all hosts it detects.

    # List all hosts seen by host-info-tools
    hit list

    # List parameters for host-info-tools enabled host
    hit params -i <hostname / IP>

Here are a few other tips / tricks

    # Reload parameters across all available hosts (supposed you have manually changed them)
    # there also tends to be an issue when a host is seen for the first time where the parameters
    # aren't properly loaded - also use this command to fix that.
    hit recache

    # Completely disable the host-info-tools service
    sudo hit disable

    # Enable the host-info-tools service
    sudo hit enable

Sometimes the first `hit` or `javis hosts` command you run isn't correct. If this seems to be the case, the second time will be correct. Often this happens the first time you attempt to launch on another host (eg: a payload) when you haven't run any other commands.
