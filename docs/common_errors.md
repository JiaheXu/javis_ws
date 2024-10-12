# Common Errors
Common errors that people see.

## Failed to update apt cache
This usually means an apt key is expired.

Run `sudo apt-key list | grep expired -B 2` this will show you any keys that are expired.

If this is the open source robotics key (osrf repository) then just run the following:

    sudo apt-key del "D248 6D2D D83D B692 72AF  E988 6717 0598 AF24 9743"
    curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -
    sudo apt update

If it is not the osrf key... then you need to try to figure out who it is from based on the email and add the new key from that organization.

## Install Host Info Tools Failed
If you get an error running javis install that has the error `Neither setup.py or pyproject.toml found`, odds are you haven't properly cloned the workspace submodules. Check out step 2 of getting started.

## Can ping robots but Host Info Tools Doesn't seen anything
This usually happens when something is wrong with your network setup that prevents multi-cast packets from getting to the host_info_server application.

First identify your primary network interface (use either `ip a` or `ifconfig`) it will probably look like one of the following:
- `ethX`
- `enpXsY`

Once you identify this interface try running the following:
```
sudo ip route add 224.0.0.0/4 dev <primary interface>
sudo /bin/bash -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
```

Then run a hit list and see if it is fixed.

install netplan
```
sudo apt-get -y install netplan.io
```

If you are using `netplan` to configure a static ip address we recommend a configuration that looks like the following (specifically with the routes added):
```
network:
    version: 2
    renderer: networkd
    ethernets:
        enp0s31f6:
            addresses:
                - 10.3.5.201/16
            nameservers:
                addresses: [8.8.8.8,8.8.4.4]
            gateway4: 10.3.0.1
            routes:
              - to: 224.0.0.0/4
                via: 0.0.0.0
```

set multicast_addr for payloads (bst doesn't need to)
```
hit params set JAVIS_MULTICAST_ADDR 239.255.100.{$ last IP number 7 for 10.3.1.7}
```
If the above configuration does not resolve the issue please contact the maintainer for further help.

## Random SSH Errors
Try running `ssh $USER@localhost` if that fails then the install / whatever scripts won't work in the first place.

Try the following: `sudo apt install openssh-server`. If that doesn't work google your specific issue or post on slack for help.
