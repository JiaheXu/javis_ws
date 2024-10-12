import yaml, sys, re, itertools
from collections import OrderedDict, deque
from collections.abc import Mapping, Iterable
from string import Template
from deployer import header
from itertools import groupby

# //////////////////////////////////////////////////////////////////////////////
# @brief import depending on python version
# //////////////////////////////////////////////////////////////////////////////
if (sys.version_info > (3, 0)):
  import queue
else:
  import queue

# //////////////////////////////////////////////////////////////////////////////
# @brief General utilities
# //////////////////////////////////////////////////////////////////////////////

class const(header.utils.constant):
  """ @brief maintains phaser's contant values"""
  delim = "." # the deliminator (constant) between sections

# //////////////////////////////////////////////////////////////////////////////
# @brief phaser tree traverser
# //////////////////////////////////////////////////////////////////////////////

def flatten(tree):
  """ @brief tree traversal entrypoint, converting yaml commands tree to a list of paths per sections. """

  phases = OrderedDict()
  phases.setdefault("", []).append(_flatten("", tree, [], [], phases))
  return phases

def _flatten(tag, tree, prefix, suffix, phases):
  """
  @brief Tree traversal, converting tree to a list of paths

  :param tag: section tag -- intermediate part of the full section name
  :param tree: the config yaml tree
  :param prefix: all commands found at previous levels
  :param suffix: all commands found at current level -- that are not recursive
  :param phases: result list -- as [ (section, cmds), ... ]

  Given a yaml structure, traverse the tree and flatten out phases and their corresponding commands
  = level-order tree traversal =
  - traverse the 'level' twice
    - first traversal to aquire all the list-like elements
    - second traversal is to propogate down the children, passing any prefix, suffix commands
      aquired from the current level

  :terminology list-like: elments in the tree that have no children
    - example: these are the 'commands'
  :terminology dict-like: elments in the tree that have children, i.e. an ordered dictionary
    - example: this is a sub-task
    - the key in the dictonary is the 'name' of the task
    - the values are the 'commands' of this child task
  """

  ## setup
  current = []  # current level's command list

  ## -- base case: tree is empty, no nodes to parse --
  if tree is None:
    return
  if len(tree) < 1:
    return

  ## level-order traversal: first traversal
  idx = 0
  for node in tree:
    # node is list-like, meaning it has no children
    if not isinstance(node, Mapping):
      suffix.insert(idx, node)
      idx +=1

  ## base case: all nodes in current level have no children
  if idx == len(tree):
    return suffix[:idx] # return only what was added

  ## -- recursive case: some nodes have children --

  ## level-order traversal: second traversal
  for node in tree:
    # node is dict-like, meaning it does have children
    if isinstance(node, Mapping):
      # get the child 'task'
      (name, child_tree) = list(node.items())[0]  # there is only ever just 1 item in the dict
      if child_tree is None:
        raise header.DeployerYamlError(
          header.fmt.error("Invalid yaml format for item: {}. Please check that section has children.".format(name)))

      # recurse on the child node
      child = _flatten(
        (tag if not tag else tag + const.delim) + name, child_tree, list(prefix), list(suffix), phases)

      # add child's flattened task commands to result set of phases
      phases.setdefault(
        (tag if not tag else tag + const.delim) + name, []).append(prefix + child + suffix)

      # add child's flattened commands to current level's command list
      current += child

    # node is list-like, meaning it has no children
    else:
      current.append(node)
      prefix.append(suffix.pop(0))

  # return current level's flattened commands
  return current

# //////////////////////////////////////////////////////////////////////////////
# @brief phaser regex matcher
# //////////////////////////////////////////////////////////////////////////////

def regex_expand(search_string):
  """
  @brief match any section expansion, '.' as section divider.
  - section is comprised of individual 'section names', divided by '.'

  :param search_string: the given section to expand for search.
  """

  tokens = [_f for _f in search_string.split('.') if _f]
  # no sections were given -- return empty
  if not tokens: return re.compile('')

  # get the regex
  prefix = '(?:.*?\\.)??('
  joiner = ')\\.(?:.*?\\.)??('
  suffix = ')(?:\\..*)?$'
  return re.compile(prefix+joiner.join(tokens)+suffix)

def section_matcher(section, phases):
  """ @brief regex match keywords for each section: gets a list of matched section to run. """

  regex_section = regex_expand(section)
  search = lambda path: not regex_section or re.match(regex_section, path)
  sections = [(name, cmds[0]) for name, cmds in list(phases.items()) if search(name) ]
  # no phase found
  if not sections:
    raise header.DeployerYamlError(header.fmt.error('No section found: {}'.format(section)))
  return sections

def filter_superset_sections(sections):
  """ @brief filter section supersets: removes all "substring" sections from list. """

  return [j for i, j in enumerate(sections) if all(
    (j[0] not in k[0]) for k in (sections[0:i] + sections[i + 1:]) )]

# //////////////////////////////////////////////////////////////////////////////
def sections(phases, sections):
  """ @brief parses yamlfile as a tree and matches phase section name return the matched' path in tree """

  return OrderedDict([ (s, filter_superset_sections(section_matcher(s, phases)) ) for s in sections])

def print_flatten(phases):
  """ @brief debug print: print flattened tree """

  print(("\n", header.fmt.title("Result"), "# of phases: ", len(phases) ))
  for name, cmds in list(phases.items()): print(( name, " : ", cmds))

def print_section_flatten(section):
  """ @brief print sections nicely: flattend sections """

  print(( "\ttotal sections : ", len(section)))
  for s in section: print(( "\t", s[0], ":", s[1]))

def phase_filter_unique(phase):
  """ @brief filter any duplicated sections in the phase """

  return const.delim.join(x for x, _ in groupby(phase.split(const.delim)))

def phase_filter(phase, filters):
  """ @brief filter remove any given filters """

  if not phase:
    raise header.DeployerYamlError(
      header.fmt.error('Something went wrong. Please notify maintainer'))

  # remove any filtered section names
  for f in filters: phase = phase.replace("{}".format(f), '')
  return phase
