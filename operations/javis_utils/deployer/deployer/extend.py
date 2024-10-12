import os, yaml, copy
from collections import OrderedDict, deque
from collections.abc import Mapping, Iterable
from string import Template
from deployer import header, phaser

# //////////////////////////////////////////////////////////////////////////////
# @brief extend default exception
# //////////////////////////////////////////////////////////////////////////////
class DeployerExtendException(Exception):
  """ @brief default deployer exception """
  pass

# //////////////////////////////////////////////////////////////////////////////
# @brief extends the yamls included in the deployer-books
# //////////////////////////////////////////////////////////////////////////////

class Extend(object):
  """ @brief extend yaml file handler """

  EXTEND_KEYWORD = "+extend"

  def __init__(self, top_level_path, script):
    self.yaml = script
    self.top_level_path = top_level_path

  def open_file(self, filepath):
    """
    @brief opens a given filepath

    :param filename: file to open

    :raises DeployerExtendException: error on invalid file path
    """

    # check file is valid
    if not os.path.isfile(filepath):
      raise DeployerExtendException(header.fmt.error("Deploy open: file is invalid: {} ".format(filepath)))
    # open file
    with open(filepath, 'r') as fo:
      script = header.utils.load(fo)
    return script

  def expand_extend_path(self, extend_path):
    """
    @brief fully expand the extend path

    :param filename: file to open

    :raises DeployerExtendException: raise error on invalid file
    """

    filepath = "{0}/{1}.yaml".format(self.top_level_path, extend_path)
    if not os.path.isfile(filepath):
      raise DeployerExtendException(header.fmt.error("Deploy extend: file is invalid: {} ".format(filepath)))
    return filepath

  def get_extend_script(self, extend_path):
    """
    @brief open the extended filepath as a script

    :param extend_path: relative extended path to file to extend
    """

    extend_file_path = self.expand_extend_path(extend_path)
    return self.open_file(extend_file_path)

  def get_extend_name(self, extend_path):
    """
    @brief get the extended file path, base name

    :param extend_path: relative extended path to file to extend
    """

    extend_file_path = self.expand_extend_path(extend_path)
    # get the basefile name as the new key into the new extended file
    base = os.path.basename(extend_file_path)
    extend_key = os.path.splitext(base)[0]
    return extend_key

  # ////////////////////////////////////////////////////////////////////////////
  # @brief print traversal over the extend tree
  # ////////////////////////////////////////////////////////////////////////////

  def print_extend(self):
    """ @brief print the yaml script as a tree (with formattting) """

    # make a deep copy of the yaml (_print will pop items)
    yamlcpy =  copy.deepcopy(self.yaml)
    self._print(yamlcpy, "")

  def _print(self, tree, tab):
    """
    @brief print the yaml script as a tree, performing the recursive print

    :param tree: current node to recursively print
    :param tab: recursive tab level to print
    """

    # empty tree
    if (tree is None) or (len(tree) < 1):
      return

    # node is ordered dict type
    if isinstance(tree, Mapping):
      od_size = len(list(tree.items()))
      if (od_size > 1):
        print((list(tree.items())))
        raise Exception("1. od size is more than 1, notify the maintainer.")

      print(("{} OD([ ".format(tab)))
      first_item = tree.popitem( last = False )
      self._print(first_item, tab + "    ")
      print(("{} ]) ".format(tab)))

    # node is str
    elif isinstance(tree, str):
      print(("{0} {1} ".format(tab, tree)))
      return

    # node is list type
    elif isinstance(tree, list):
      print(("{0} [ ".format(tab)))
      for item in tree:
        self._print(item, tab + "    ")
      print(("{0} ] ".format(tab)))

    # node is tuple type
    elif isinstance(tree, tuple):
      lst = list(tree)
      print(("{0} ( {1}, ".format(tab, lst[0])))
      self._print(lst[1], tab + "    ")
      print(("{} ) ".format(tab)))

  # ////////////////////////////////////////////////////////////////////////////
  # @brief string representation traversal over the extend tree
  # ////////////////////////////////////////////////////////////////////////////

  def repr(self):
    """ @brief create a string representation of the yaml script as a tree (with formattting) """

    self.repr_str_ = ""
    # make a deep copy
    yamlcpy =  copy.deepcopy(self.yaml)
    return self._repr(yamlcpy, "")

  def _repr(self, tree, tab):
    """
    @brief create a string representation of the yaml script as a tree, performing the recursive print

    :param tree: current node to recursively print
    :param tab: recursive tab level to print
    """

    # empty tree
    if (tree is None) or (len(tree) < 1):
      return

    # node is ordered dict type
    if isinstance(tree, Mapping):
      od_size = len(list(tree.items()))
      if (od_size > 1):
        print((list(tree.items())))
        raise Exception("2. od size is more than 1, notify the maintainer.")

      self.repr_str_ += "{} OD([ \n".format(tab)
      first_item = tree.popitem(last=False)
      self._repr(first_item, tab + "    ")
      self.repr_str_ += "{} ]) \n".format(tab)

    # node is str
    elif isinstance(tree, str):
      self.repr_str_ += "{0} {1} \n".format(tab, tree)
      return

    # node is list type
    elif isinstance(tree, list):
      self.repr_str_ += "{0} [ \n".format(tab)
      for item in tree:
        self._repr(item, tab + "    ")
      self.repr_str_ += "{0} ] \n".format(tab)

    # node is tuple type
    elif isinstance(tree, tuple):
      lst = list(tree)
      self.repr_str_ += "{0} ( {1}, \n".format(tab, lst[0])
      self._repr(lst[1], tab + "    ")
      self.repr_str_ += "{} ) \n".format(tab)

  def traverse(self, yaml):
    return self.traversal(yaml, "")

  # ////////////////////////////////////////////////////////////////////////////
  # @brief traversal over the extend tree
  # ////////////////////////////////////////////////////////////////////////////

  def traversal(self, yaml, tab):
    """
    @brief traverse the yaml script as a tree and perform any extensions.

    :param yaml: current yaml script to recursively traverse
    :param tab: recursive tab level to print
    """

    # make a deep copy
    yamlcpy =  copy.deepcopy(yaml)
    return self._traversal(yamlcpy, tab)

  def _traversal(self, tree, tab):
    """
    @brief traverse the yaml script as a tree and perform any extensions, performing the recursive print

    :param tree: current node to recursively print
    :param tab: recursive tab level to print
    """

    # empty tree
    if (tree is None) or (len(tree) < 1): return

    # node is ordered dict type
    if isinstance(tree, Mapping):
      # the ordered dictionaries in the yaml should only have one key values -- not completely sure...
      od_size = len(list(tree.items()))
      if (od_size > 1):
        print ("hello?")
        print((list(tree.items())))
        raise Exception("3. od size is more than 1, notify the maintainer.")
      first_item = tree.popitem( last = False )

      # create the ordered dictionary
      tmp_od = OrderedDict()
      key = first_item[0]
      if (key == Extend.EXTEND_KEYWORD):
        key = self.get_extend_name(first_item[1])
      tmp_od[key] = self._traversal(first_item, tab + "    ")
      return tmp_od

    # node is str
    elif isinstance(tree, str):
      return tree

    # node is list type
    elif isinstance(tree, list):
      tmp_list = []
      for item in tree:
        tmp_list.append( self._traversal(item, tab + "    "))
      return tmp_list

    # node is tuple type
    elif isinstance(tree, tuple):
      # list-ify the tuple to have index access
      lst = list(tree)

      # extended yaml, parse the tuple values
      if (lst[0] == Extend.EXTEND_KEYWORD):
        extend_path = lst[1]
        extend_script = self.get_extend_script(extend_path)
        extend_key = self.get_extend_name(extend_path)
        # recurse the extended yaml
        return self.traversal(extend_script, tab + "    ")

      # current yaml, parse the tuple values
      else:
        return self._traversal(lst[1], tab + "    ")

  # ////////////////////////////////////////////////////////////////////////////
  # @brief compare extend trees
  # ////////////////////////////////////////////////////////////////////////////

  def compare(self, y1, y2):
    """ @brief compare two yamls structures entrypoint """

    y1cpy =  copy.deepcopy(y1)
    y2cpy =  copy.deepcopy(y2)
    return self._compare(y1cpy, y2cpy)

  def _compare(self, tree1, tree2):
    """ @brief compare two yamls structures """

    # base case: check both are none
    if tree1 is None and tree2 is None:
      return True

    # base case: check both have 0 length
    if len(tree1) < 1 and len(tree2) < 1:
      return True

    # node is ordered dict type
    if isinstance(tree1, Mapping) and isinstance(tree2, Mapping):
      # get the first item in tree1
      od_size = len(list(tree1.items()))
      if (od_size > 1):
        raise Exception("od size, tree1, is more than 1, notify the maintainer.")
      tree1_first_time = tree1.popitem( last = False )

      # get the first item in tree2
      od_size = len(list(tree2.items()))
      if (od_size > 1):
        raise Exception("od size, tree2, is more than 1, notify the maintainer.")
      tree2_first_time = tree2.popitem( last = False )

      # recurse
      return self._compare(tree1_first_time, tree2_first_time)

    # node is str
    elif isinstance(tree1, str) and isinstance(tree2, str):
      return tree1 == tree2

    # node is list type
    elif isinstance(tree1, list) and isinstance(tree2, list):
      if len(tree1) != len(tree2): return False
      for item1, item2 in zip(tree1, tree2):
        if not self._compare(item1, item2): return False
      return True

    # node is tuple type
    elif isinstance(tree2, tuple) and isinstance(tree2, tuple):
      # list-ify the tuple to have index access
      lst1 = list(tree1)
      lst2 = list(tree2)

      # tuple keys need to match
      if lst1[0] != lst2[0]: return False

      # recurse on values
      return self._compare(lst1[1], lst2[1])

    # nothing matches
    return False
