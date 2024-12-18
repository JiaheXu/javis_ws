#!/usr/bin/env python3
import os
import sys
import glob
import shutil
import subprocess

from setuptools import setup


setup(
    name='host-info-tools',
    version='0.0.1',
    include_package_data = True,
    author = "Jiahe",
    author_email = "jiahex@andrew.cmu.edu",
    maintainer = "Jiahe",
    maintainer_email = "jiahex@andrew.cmu.edu",
    description = "Uses multicast to identify hosts across a network, distribute metadata about them and add them to /etc/hosts",
    packages = ['host_info_tools'],
    package_dir={'host_info_tools': "src/host_info_tools"},
    data_files = [
        ("host_info_tools", [
            "config/host_info_server.service",
            "config/host_info_server.yaml"
            ])
    ],
    scripts=['src/host_info_server', 'src/hit'],
    install_requires=['pyyaml', 'ifcfg', 'python-dotenv'],
    zip_safe=False
)