import unittest
import re
from deployer import color, cli, phaser, repl
from ..paths import *

class SimpleTests(unittest.TestCase):
  # yaml config to test
  file = 'test1.yaml'
  def read_yaml(self, file_name):
    return os.path.join(PHASE_DIR, file_name)

  def test_phaser(self):
    ''' Test creating the full tree of sections to perform '''
    print ("\n", color.title("Testing..."))

    # config file to test
    TEST_FILE = self.read_yaml(self.file)
    script = header.utils.load(open(TEST_FILE, 'r'))
    phases = phaser.flatten(script)
    # phaser.print_flatten(phases)
    # color.divider()

    ### Check each individual case

    ## test helpers
    validate_assert = lambda a, b : self.assertEqual(a, b)
    def perform_test_case(name, cmd):
      # get task in list
      (test_name, test_cmds) = phases.items()[self.idx]
      # perform the test assertions
      validate_assert(name, test_name)
      validate_assert(cmds, test_cmds[0])
      # index counter for next task in list
      self.idx+=1

    ## Test setup
    self.idx = 0

    ## Test case
    self.assertEqual(7, len(phases))

    ## Test case
    name = ""
    cmds = ['pwd', 'echo', 'sleep1', 'ls', 'cat', 'G', 'I', 'something', 'X', 'Y', 'Z', 'awake']
    perform_test_case(name, cmds)

    ## Test case
    name = "sleep"
    cmds = ['pwd', 'echo', 'sleep1', 'awake']
    perform_test_case(name, cmds)

    ## Test case
    name = "task1.sub1.sub2"
    cmds = ['pwd', 'echo', 'ls', 'cat', 'something', 'awake']
    perform_test_case(name, cmds)

    ## Test case
    name = "task1.sub1.sub3"
    cmds = ['pwd', 'echo', 'ls', 'G', 'I', 'something', 'awake']
    perform_test_case(name, cmds) 

    ## Test case
    name = "task1.sub1"
    cmds = ['pwd', 'echo', 'ls', 'cat', 'G', 'I', 'something', 'awake']
    perform_test_case(name, cmds)

    ## Test case
    name = "task1.other"
    cmds = ['pwd', 'echo', 'something', 'X', 'Y', 'Z', 'awake']
    perform_test_case(name, cmds)

    ## Test case
    name = "task1"
    cmds = ['pwd', 'echo', 'ls', 'cat', 'G', 'I', 'something', 'X', 'Y', 'Z', 'awake']
    perform_test_case(name, cmds)

  def test_sections(self):
    ''' Tests whether the correct sections are chosen '''
    print ("\n", color.title("Testing..."))
    # config file to test
    TEST_FILE = self.read_yaml(self.file)

    ### setup section matcher
    script = header.utils.load(open(TEST_FILE, 'r'))
    phases = phaser.flatten(script)
    # phaser.print_flatten(phases)

    ### perform the sections matcher regex parser
    arg = "task1"
    sections = phaser.section_matcher(arg, phases)

    ### Check each individual case
    # color.divider()

    ## Test case
    self.assertEqual(7, len(phases))
    self.assertEqual(5, len(sections))

    ## Test setup
    self.idx = 0

    ## test helpers
    validate_assert = lambda a, b : self.assertEqual(a, b)
    def perform_test_case(name, cmd):
      # get task in list
      (test_name, test_cmds) = phases.items()[self.idx]
      # perform the test assertions
      validate_assert(name, sections[self.idx][0])
      validate_assert(cmds, sections[self.idx][1])
      # index counter for next task in list
      self.idx+=1

    ## Test case
    name = 'task1.sub1.sub2'
    cmds = ['pwd', 'echo', 'ls', 'cat', 'something', 'awake']
    perform_test_case(name, cmds)

    ## Test case
    name = 'task1.sub1.sub3'
    cmds = ['pwd', 'echo', 'ls', 'G', 'I', 'something', 'awake']
    perform_test_case(name, cmds)

    ## Test case
    name = "task1.sub1"
    cmds = ['pwd', 'echo', 'ls', 'cat', 'G', 'I', 'something', 'awake']
    perform_test_case(name, cmds)

    ## Test case
    name = 'task1.other'
    cmds = ['pwd', 'echo', 'something', 'X', 'Y', 'Z', 'awake']
    perform_test_case(name, cmds)

    ## Test case
    name = 'task1'
    cmds = ['pwd', 'echo', 'ls', 'cat', 'G', 'I', 'something', 'X', 'Y', 'Z', 'awake']
    perform_test_case(name, cmds)

  def test_replwrap(self):
    ''' test single command output '''
    print ("\n", color.title("Testing..."))
    cmds = ['ls -all']
    repl.run_replwrap(cmds)
