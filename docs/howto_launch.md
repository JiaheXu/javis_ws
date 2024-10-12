# Launching JAVIS
There are two ways to launch the javis stack - command line and launch icon.

## Command Line
The `javis-launch` (aliased to `javis launch`) tool allows you to launch different configurations on different hosts.

The generally form of the launch command is the following:

      javis launch --launch <configuration> -- <host>

Heres a few specific launch commands that are useful

      # List available launch configurations on your machine
      javis launch --list

      # Launch the default configuration on your machine
      javis launch

      # Launch a specific configuration on your machine
      javis launch --launch <config>

      # List available launch configurations on payload
      javis launch --list -- <payload name>

      # Launch the default configuration on a payload
      javis launch -- <payload name>

      # Launch a specific configuration on a payload
      javis launch --launch <config> -- <payload name>

      # Launch the default configuration across multiple payloads (launches tmux in background)
      javis launch -- <payload name a> <payload name b>

      # Attach to a running launch configuration on the local machine
      javis launch --attach

      # Attach to a running launch configuration on a payload
      javis launch --attach -- <payload name>

      # Detach a running launch configuration (save comms bandwidth)
      javis launch --detach [-- <payload name>]

      # Stop the launch
      javis launch --stop

      # Stop the launch on a payload
      javis launch --stop -- <payload name>
