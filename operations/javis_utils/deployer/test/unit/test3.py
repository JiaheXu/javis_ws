import unittest
import re, argparse
from deployer import color, cli, phaser, repl
from ..paths import *

class SimpleTests(unittest.TestCase):
  # Bug: if the same name in multiple places, it will example to each one matched.
  #   TODO: make it a double .. task1..subt1. whatever, not doing now. put in readme.

  # yaml config to test
  file = 'test3.yaml'

  def read_yaml(self, file_name):
    # get test file
    return os.path.join(PHASE_DIR, file_name)

  def test_section_prompt(self):
    """ Tests whether the correct sections are performed based on a section match """

    # config file to test
    TEST_FILE = self.read_yaml(self.file)
    script = header.utils.load(open(TEST_FILE, 'r'))
    phases = phaser.flatten(script)
    # color.divider()
    # phaser.print_flatten(phases)

    # setup command line args
    parser = argparse.ArgumentParser()
    args = cli.parse_args()

    ### Check each individual case

    # Test helpers
    get_section_key = lambda sections, sidx, pidx : sections[sidx][1][pidx][0] # last is : (key:cmds)
    validate_assert = lambda a, b : self.assertEqual(a, b)
    def perform_test_case(test, result, section, phase):
      validate_assert(get_section_key(test, section, phase), result)

    # Test case: 'args -a' -> check all tasks are listed
    sections = phaser.sections(phases, args)
    perform_test_case(sections.items(), "task1.sub1", section=0, phase=0)
    perform_test_case(sections.items(), "task1.sub2", section=0, phase=1)
    perform_test_case(sections.items(), "task1.subt-task2.subt1", section=0, phase=2)
    perform_test_case(sections.items(), "task1.subt-task2.subt2", section=0, phase=3)
    perform_test_case(sections.items(), "task1.sub3", section=0, phase=4)
    args.all = False  # cleanup test case

    ## Test case
    args.sections = ["task1.sub1"]
    sections = phaser.sections(phases, args)
    perform_test_case(sections.items(), "task1.sub1", section=0, phase=0)

    ## Test case
    args.sections = ["task1.sub2"]
    sections = phaser.sections(phases, args)
    perform_test_case(sections.items(), "task1.sub2", section=0, phase=0)

    ## Test case
    args.sections = ["task1.subt-task2"]
    sections = phaser.sections(phases, args)
    perform_test_case(sections.items(), "task1.subt-task2.subt1", section=0, phase=0)
    perform_test_case(sections.items(), "task1.subt-task2.subt2", section=0, phase=1)

    ## Test case
    args.sections = ["task1.subt-task2.subt1"]
    sections = phaser.sections(phases, args)
    perform_test_case(sections.items(), "task1.subt-task2.subt1", section=0, phase=0)

    ## Test case
    args.sections = ["task1.sub3"]
    sections = phaser.sections(phases, args)
    perform_test_case(sections.items(), "task1.sub3", section=0, phase=0)

    ## Test case
    args.sections = ["task1.sub3", "task1.sub1"]
    sections = phaser.sections(phases, args)
    perform_test_case(sections.items(), "task1.sub3", section=0, phase=0)
    perform_test_case(sections.items(), "task1.sub1", section=1, phase=0)

    ## Test case
    args.sections = ["task1.sub3", "task1.subt-task2"]
    sections = phaser.sections(phases, args)
    perform_test_case(sections.items(), "task1.sub3", section=0, phase=0)
    perform_test_case(sections.items(), "task1.subt-task2.subt1", section=1, phase=0)
    perform_test_case(sections.items(), "task1.subt-task2.subt2", section=1, phase=1)

  def test_phase_run(self):
    print ("\n")
    # print "\n", color.title("Testing..." )
    # config file to test
    TEST_FILE = self.read_yaml(self.file)
    script = header.utils.load(open(TEST_FILE, 'r'))
    phases = phaser.flatten(script)

    # setup command line args
    parser = argparse.ArgumentParser()
    args = cli.parse_args()
    args.all = False  # cleanup test case
    args.yaml = TEST_FILE
    args.sections = ["task1.sub3", "task1.subt-task2", "task1"]
    cli.phase_run(args)
