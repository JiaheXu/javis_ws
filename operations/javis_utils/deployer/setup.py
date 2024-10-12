from setuptools import setup

setup(name='deployer',
      version='0.1',
      description='deployer tasks, read from yaml files',
      packages=['deployer'],
      install_requires=['pexpect'],
      zip_safe=False)