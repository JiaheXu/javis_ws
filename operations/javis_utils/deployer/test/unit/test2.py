import unittest
import re
import sys, os, re, argparse
from deployer import color, cli, phaser, repl
from ..paths import *

class IntegrationTests(unittest.TestCase):
  # yaml config to test
  testfile = "test2.yaml"

  def read_yaml(self, file_name):
    # get test file
    return os.path.join(PHASE_DIR, file_name)

  def test_phase_run(self):
    print ("\n", color.title("Testing..."))
    # config file to test
    TEST_FILE = self.read_yaml(self.testfile)

    # setup command line args
    parser = argparse.ArgumentParser()
    args = cli.parse_args()
    print ("Args are : ", args)
    args.yaml = TEST_FILE
    cli.phase_run(args)