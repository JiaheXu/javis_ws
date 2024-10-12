#!/usr/bin/env python3
import host_info_tools as hit
from host_info_tools import argparse as hit_ap
import os
import sys
import yaml
import jinja2
import shutil

icon_template = """# JAVIS LAUNCH CONFIGURATION
arguments: {{ arguments }}
"""

## Default directories -- should be same as fed to javis hosts
home_dir = os.path.expanduser("~")
default_icons_directory = os.path.join(home_dir, "Desktop", "JAVIS")
default_ssh_directory = os.path.join(home_dir, ".ssh", "javis.d")
default_robots_config = os.path.join(default_ssh_directory, "hosts.yaml")

if "JAVIS_OPERATIONS" in os.environ:
    default_launch_config = os.path.join(os.environ["JAVIS_OPERATIONS"], "javis_deploy", "workspace_config.yaml")
else:
    print("JAVIS_OPERATIONS variable is not set. Unable to run.")
    exit(1)

if __name__ == "__main__":
    ap = hit_ap.Arguments(["config", "icons_dir"])
    ap.parse_arguments(sys.argv[1:])
    icons_dir = ap.get_flag_value(["icons_dir"], default_icons_directory)
    launch_config_path = ap.get_flag_value(["launch_config"], default_launch_config)
    robots_config_path = ap.get_flag_value(["robots_config"], default_robots_config)

    robots_config = None
    launch_config = None
    if os.path.exists(robots_config_path):
        try:
            with open(robots_config_path, 'r') as f:
                robots_config = yaml.load(f, Loader=yaml.FullLoader)
        except Exception as err:
            pass
    if os.path.exists(launch_config_path):
        try:
            with open(launch_config_path, 'r') as f:
                launch_config = yaml.load(f, Loader=yaml.FullLoader)
        except Exception as err:
            pass
    if robots_config is None:
        print("Error loading robots config at %s"%robots_config_path)
        exit(1)
    if launch_config is None:
        print("Error loading launch config at %s"%launch_config_path)
        exit(1)
    if "hosts" not in launch_config:
        print("Error loading hosts in launch config at %s"%robots_config_path)
        exit(1)
    launch_config = launch_config["hosts"]

    if len(launch_config) == 0 or len(robots_config) == 0:
        print("Error: no robots or no launch configs. Unable to create icons.")
        exit(1)

    if os.path.exists(icons_dir):
        shutil.rmtree(icons_dir)
    os.makedirs(icons_dir)

    for robot in robots_config:
        print(robot)
        if "designator" not in robots_config[robot] or "system_type" not in robots_config[robot] or "system_component" not in robots_config[robot]:
            print("Unable to generate icons for %s, keys missing."%robot)
            print("Run 'javis hosts adopt %s' when host is connected or 'javis hosts forget %s' to make this error go away."%(robot, robot))
            print()
            continue
        alias = robots_config[robot]["designator"]
        system_type = robots_config[robot]["system_type"]
        system_component = robots_config[robot]["system_component"]

        system_descrip = "%s.%s"%(system_type, system_component)
        if system_descrip not in launch_config:
            print("Error: description for [%s] is not in config, unable to generate icons for %s (%s)"%(system_type, robot, alias))
            continue

        sys_config = launch_config[system_descrip]["launch"]

        robot_dir = os.path.join(icons_dir, alias)
        try:
            os.makedirs(robot_dir)
        except Exception as err:
            print("Error creating [%s] possible system id overlap?"%robot_dir)
            continue

        icons = []

        for l in sys_config["launches"]:
            icons.append((os.path.join(robot_dir, "%s.launch.%s"%(alias, l)), { "arguments": "--launch %s -- %s"%(l, alias) } ))
        
        icons.append((os.path.join(robot_dir, "%s.launch"%(alias)), { "arguments": "-- %s"%(alias) } ))
        icons.append((os.path.join(robot_dir, "%s.stop"%(alias)), { "arguments": "--stop -- %s"%(alias) }))
        icons.append((os.path.join(robot_dir, "%s.attach"%(alias)), { "arguments": "--attach -- %s"%(alias) }))
        icons.append((os.path.join(robot_dir, "%s.detach"%(alias)), { "arguments": "--remote-detach -- %s"%(alias) }))

        j_template = jinja2.Template(icon_template)
        for i in icons:
            path, dargs = i
            with open(path, "w+") as f:
                r = j_template.render(dargs)
                f.write(r)