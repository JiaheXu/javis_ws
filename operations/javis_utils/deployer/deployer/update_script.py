import os
import sys, os, re, argparse, glob
from deployer import color, phaser, repl, header
import yaml
import collections

ROOT = "../../../rosinstall_/"
EXTENSION = ".rosinstall"

# Creating a yaml representer to map to treat OrderedDict as a regular mapped set
# https://stackoverflow.com/questions/45253643/order-preservation-in-yaml-via-python-script
def ordered_dict_representer(self, value):  # can be a lambda if that's what you prefer
    return self.represent_mapping('tag:yaml.org,2002:map', list(value.items()))

# Check for the local name at each of the git to see if it matches
# the local_name that needs to be changed, and update the version
# accordingly
def open_file(file_name):
    fo = open(file_name, 'r')
    script = header.utils.load(fo)
    fo.close()
    return script

def manual_rosinstall(script, file_name, file, root, local_name, version):

    # Add representer to read the OrderedDict type
    yaml.add_representer(collections.OrderedDict, ordered_dict_representer)

    for j in range(len(script)):
        od = script[j]
        for i, (key, inner_od) in enumerate(od.items()):
            if list(inner_od.values())[0] == local_name:
                inner_od[list(inner_od.keys())[2]] = version

    # Creating a new file named updated_file.rosinstall
    updated_file_name = os.path.join(root, 'updated_' + file)

    with open(updated_file_name, 'w') as outfile:
        yaml.dump(script, outfile, default_flow_style=False, sort_keys = False)
    return (updated_file_name, file_name)

# Check to see if the file needs to be updated
def check_to_update(script, file, root, local_name, version):

    # Add representer to read the OrderedDict type
    yaml.add_representer(collections.OrderedDict, ordered_dict_representer)

    for j in range(len(script)):
        od = script[j]
        for i, (key, inner_od) in enumerate(od.items()):
            if list(inner_od.values())[0] == local_name:
                return True
    return False

def main(local_name, version):
    # Recursively check file with .rosinstall to update local_name and version
    updated_file_names = []
    for root, subdirs, files in os.walk(ROOT):
        for file in files:
            if file.split('.')[-1] == 'rosinstall':
                file_name = os.path.join(root, file)
                script = open_file(file_name)
                if check_to_update(script, file, root, local_name, version):
                    updated_file_name, old_file = manual_rosinstall(script, file_name, file, root, local_name, version)
                    updated_file_names.append((updated_file_name, old_file))

    # Going through individual files to update accroding to user inputs
    for (updated_file_name, old_file) in updated_file_names:
        prompt = "Replace %s, y or n? " % old_file
        response = input(prompt)
        if response == 'y':
            os.rename(updated_file_name, old_file)
        elif response == 'n':
            os.remove(updated_file_name)
