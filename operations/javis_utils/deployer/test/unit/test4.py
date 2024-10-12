import unittest, os
import re, argparse, yaml
from deployer import color, cli, phaser, repl, update_script, extend
from ..paths import *


def mock_raw_input(s):
  return 'y'

class SimpleTests(unittest.TestCase):
  # yaml config to test
  ROOT = "./update_script/rosinstall_/"
  EXTENSION = ".rosinstall"
  ROOT_GIT = "./update_script/"

  filename = "basestation.rosinstall"
  top_path = os.path.dirname(os.path.abspath(__file__))
  filepath = "{}/../update_script/rosinstall_/basestation/".format(top_path)

  file = "basestation.rosinstall"
  root = "{}/../update_script/rosinstall_/".format(top_path)
  root_git = "{}/../update_script/".format(top_path)

  def read_yaml(self, file_name):
    return os.path.join(PHASE_DIR, file_name)

  def test_invalid_user_inputs(self):
    self.assertRaises(update_script.RosinstallError,
                      update_script.main,
                      SimpleTests.ROOT,
                      SimpleTests.EXTENSION,
                      SimpleTests.ROOT_GIT,
                      "basestation.hardware", "", "")

    # Invalid project path
    self.assertRaises(update_script.RosinstallError,
                      update_script.main,
                      SimpleTests.ROOT,
                      SimpleTests.EXTENSION,
                      SimpleTests.ROOT_GIT,
                      "basestation.hardware", "", "")

    self.assertRaises(update_script.RosinstallError,
                      update_script.main,
                      SimpleTests.ROOT,
                      SimpleTests.EXTENSION,
                      SimpleTests.ROOT_GIT,
                      "basestation", "", "")

    #Invalid local_name
    self.assertRaises(update_script.RosinstallError,
                      update_script.main,
                      SimpleTests.ROOT,
                      SimpleTests.EXTENSION,
                      SimpleTests.ROOT_GIT,
                      "","invalid_local_name", "version_numbers")

    # Invalid user inputs
    self.assertRaises(update_script.RosinstallError,
                      update_script.main,
                      SimpleTests.ROOT,
                      SimpleTests.EXTENSION,
                      SimpleTests.ROOT_GIT,
                      "basestation.hardware",
                      "invalid input", "invalid input")

    self.assertRaises(update_script.RosinstallError,
                      update_script.main,
                      SimpleTests.ROOT,
                      SimpleTests.EXTENSION,
                      SimpleTests.ROOT_GIT,
                      "basestation.hardware",
                      "", "invalid input")

    self.assertRaises(update_script.RosinstallError,
                      update_script.main,
                      SimpleTests.ROOT,
                      SimpleTests.EXTENSION,
                      SimpleTests.ROOT_GIT,
                      "basestation.hardware",
                      "invalid input", "")

    self.assertRaises(update_script.RosinstallError,
                      update_script.main,
                      SimpleTests.ROOT,
                      SimpleTests.EXTENSION,
                      SimpleTests.ROOT_GIT,
                      "", "invalid input", "")

    self.assertRaises(update_script.RosinstallError,
                      update_script.main,
                      SimpleTests.ROOT,
                      SimpleTests.EXTENSION,
                      SimpleTests.ROOT_GIT,
                      "", "", "invalid input")

    self.assertRaises(update_script.RosinstallError,
                      update_script.main,
                      SimpleTests.ROOT,
                      SimpleTests.EXTENSION,
                      SimpleTests.ROOT_GIT,
                      "", "", "")

  def test_manual_rosinstall(self):
    local_name = "base_main_class"
    version =  "1234"
    project = ""

    # Testing manual update using mock raw_input
    update_script.raw_input = mock_raw_input
    update_script.main(SimpleTests.root, SimpleTests.EXTENSION,
                       SimpleTests.root_git, project, local_name, version)
    script = update_script.open_file(SimpleTests.filepath + SimpleTests.filename)
    # Checking that the version got changed
    for j in range(len(script)):
      od = script[j]
      for i, (key, inner_od) in enumerate(od.iteritems()):
        if inner_od.values()[0] == local_name:
          self.assertEqual(version, inner_od[inner_od.keys()[2]])
    return False

  def test_git_update(self):
    # Testing git_update
    local_name = ""
    version =  ""
    project = "basestation"

    newest_git = "9931153b7cbb7620b04107ece149c9de2a617b53"

    update_script.main(SimpleTests.root, SimpleTests.EXTENSION,
                       SimpleTests.root_git, project, local_name, version)
    script = update_script.open_file(SimpleTests.filepath + SimpleTests.filename)
    # Checking that the version got updated to newest git_commit
  
    for j in range(len(script)):
      od = script[j]
      for i, (key, inner_od) in enumerate(od.iteritems()):
        if inner_od.values()[0] == local_name:
          self.assertEqual(newest_git, inner_od[inner_od.keys()[2]])

    return True


class ExpandYamlTests(unittest.TestCase):

  def print_title(self, text):
    print (color.newline())
    color.divider()
    print (color.text(text))

  def expand_filepath(self, file_name):
    return os.path.join(PHASE_DIR, file_name)

  def open_file(self, filepath):
    # open file
    fo = open(filepath, 'r')
    script = header.utils.load(fo)
    fo.close()
    return script

  def test_extender(self):
    """ Testing out extend """
    self.print_title("test_extender")

    # load the script -- script is the yaml as a ordered dictionary
    file = 'nested/test2.yaml'
    script = self.open_file(self.expand_filepath(file))
    extender = extend.Extend(PHASE_DIR, script)
    print ("---------------------")
    extender.print()
    print ("--------------------- TRAVERSAL:")
    tmp_tree = extender.traverse(extender.yaml)
    print ("orig yaml is  : {}".format(script))
    print ("tree is result: {}".format(tmp_tree))

    print ("--------------------- print check after traversal: ")
    extender_check = extend.Extend(PHASE_DIR, tmp_tree)
    extender_check.print()

  def test_simple_non_extended(self):
    """ Simple non extended test """
    self.print_title("test_simple_non_extended")

    # load the script -- script is the yaml as a ordered dictionary
    file = 'nested/test1.yaml'
    script = self.open_file(self.expand_filepath(file))
    extender = extend.Extend(PHASE_DIR, script)
    # traverse
    tree = extender.traverse(script)
    # check structures are equal (unit test compare structures)
    self.assertEqual(script, tree)
    # check comparision (custom compare structures)
    self.assertTrue(extender.compare(script, tree))

  def test_simple_extended(self):
    """ Simple extended test """
    self.print_title("test_simple_extended")

    # load the script -- script is the yaml as a ordered dictionary
    file = 'nested/test2.yaml'
    script = self.open_file(self.expand_filepath(file))
    extender = extend.Extend(PHASE_DIR, script)
    # traverse
    tree = extender.traverse(script)
    # check structures are not equal, extend is larger
    self.assertNotEqual(script, tree)
    # check comparision (custom compare structures)
    self.assertFalse(extender.compare(script, tree))

    # check the specific extend structures
    self.assertEqual(tree[0], "pwd")

    # section: 'nested'
    od = tree[1]
    self.assertEqual(len(od.items()), 1)
    od_val = list(od.popitem( last = False ))
    self.assertEqual(len(od_val), 2)
    self.assertEqual(od_val[0], "nested")
    self.assertEqual(type(od_val[1]), list)

    # section: 'nested' values
    od_vals = od_val[1]
    # check the non-nested values
    self.assertEqual(od_vals[0], "ls")
    self.assertEqual(od_vals[2], "ls -all")

    # section: 'extend' tree
    od = od_vals[1]
    self.assertEqual(len(od.items()), 1)
    od_val = list(od.popitem( last = False ))
    self.assertEqual(len(od_val), 2)
    self.assertEqual(od_val[0], "test3")
    self.assertEqual(type(od_val[1]), list)
    od_vals = od_val[1]

    # print ("od is : {}".format(od_vals))
    self.assertEqual(od_vals[0], "ls -all")
    self.assertEqual(od_vals[2], "whoami")

    # section 'top'
    od = od_vals[1]
    self.assertEqual(len(od.items()), 1)
    od_val = list(od.popitem( last = False ))
    self.assertEqual(len(od_val), 2)
    self.assertEqual(od_val[0], "top")
    self.assertEqual(type(od_val[1]), list)
    od_vals = od_val[1]

    self.assertEqual(od_vals[0], "uname -a")

    # section: 'top.sub' tree
    od = od_vals[1]
    self.assertEqual(len(od.items()), 1)
    od_val = list(od.popitem( last = False ))
    self.assertEqual(len(od_val), 2)
    self.assertEqual(od_val[0], "sub")
    self.assertEqual(type(od_val[1]), list)
    od_vals = od_val[1]
    self.assertEqual(od_vals[0], "echo \"sub section\"")

  def test_multi_extended(self):
    pass

  def test_invalid_extend_file(self):
    """ Test invalid extension filenames: non existant filename """
    self.print_title("test_invalid_extend_file")

    # load the script -- script is the yaml as a ordered dictionary
    file = 'nested/test4.yaml'
    script = self.open_file(self.expand_filepath(file))
    extender = extend.Extend(PHASE_DIR, script)
    # check valid raise, incorrect filename exception
    self.assertRaises(extend.DeployerExtendException, extender.traverse, script)

  def test_invalid_infinite_loop_filename(self):
    # TODO: cant have same file be extender -- infinite loop
    """ Test invalid extension filenames: same filename as the yaml being parsed. """
    self.print_title("test_invalid")

    # load the script -- script is the yaml as a ordered dictionary
    file = 'nested/test5.yaml'
    script = self.open_file(self.expand_filepath(file))
    extender = extend.Extend(PHASE_DIR, script)
    # check valid raise, same filename exception
    # self.assertRaises(extend.DeployerExtendException, extender.traverse, script)

  def test_very_simple_extended(self):
    """ Simple extended test """
    # TODO: test6.yaml

  def test_parse_sections_on_extend(self):
    pass
