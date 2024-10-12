
import os, re, contextlib, yaml
from collections import OrderedDict

# globals
BLUE      = '\033[94m'
GREEN     = '\033[92m'
RED       = '\033[91m'
YELLOW    = '\033[93m'
CYAN      = '\033[96m'
MAGENTA   = '\033[35m'
BOLD      = '\033[1m'
UNDERLINE = '\033[4m'
DEFAULT   = '\033[0m'

# //////////////////////////////////////////////////////////////////////////////
# @brief Deployer Exception
# //////////////////////////////////////////////////////////////////////////////

# @brief exceptions
class DeployerYamlError(Exception):
  """ @brief default deployer exception overloader. """
  pass

@contextlib.contextmanager
def with_general_exception(message):
  """ @brief try-catch deployer-exception raise wrapper, intended for generic, utility functions. """

  try:
    yield
  except Exception as e:
    raise DeployerYamlError(message)

# //////////////////////////////////////////////////////////////////////////////
# @brief Formatting Styles
# //////////////////////////////////////////////////////////////////////////////

class fmt():
  """ @brief variety of different string formatting styles. """

  @staticmethod
  def title(instr):
    return BLUE+BOLD +"== "+instr+" == \n "+DEFAULT

  @staticmethod
  def subtitle(instr):
    return BLUE+BOLD+UNDERLINE+MAGENTA+instr+DEFAULT

  @staticmethod
  def minorsubtitle(instr):
    return BLUE+BOLD+instr+DEFAULT

  @staticmethod
  def subsubtitle(instr):
    return BLUE+BOLD+YELLOW+instr+DEFAULT

  @staticmethod
  def text(instr):
    return GREEN+instr+DEFAULT

  @staticmethod
  def btext(instr):
    return GREEN+BOLD+instr+DEFAULT

  @staticmethod
  def bcoltext(instr, col):
    return col+BOLD+instr+DEFAULT

  @staticmethod
  def error(instr):
    return RED+BOLD+instr+DEFAULT

  @staticmethod
  def warn(instr):
    return YELLOW+BOLD+instr+DEFAULT

  @staticmethod
  def divider():
    print((GREEN + "-" * 50 + DEFAULT))

  @staticmethod
  def ps_format():
    return BLUE+BOLD

  @staticmethod
  def newline():
    return "\n"

class stdout():
  """ @brief variety of different string print formatting styles """

  @staticmethod
  def title(instr):
    print((fmt.title(instr)))

  @staticmethod
  def subtitle(instr):
    print((fmt.subtitle(instr)))

  @staticmethod
  def minorsubtitle(instr):
    print((fmt.minorsubtitle(instr)))

  @staticmethod
  def subsubtitle(instr):
    print((fmt.subsubtitle(instr)))

  @staticmethod
  def text(instr):
    print((fmt.text(instr)))

  @staticmethod
  def btext(instr):
    print((fmt.btext(instr)))

  @staticmethod
  def bcoltext(instr, col):
    return col+BOLD+instr+DEFAULT

  @staticmethod
  def error(instr):
    print((fmt.error(instr)))

  @staticmethod
  def warn(instr):
    print((fmt.warn(instr)))

  @staticmethod
  def divider():
    print((fmt.divider()))

  @staticmethod
  def ps_format():
    print((fmt.ps_format()))

  @staticmethod
  def newline():
    print((fmt.newline()))

# //////////////////////////////////////////////////////////////////////////////
# @brief General Utility Functions
# //////////////////////////////////////////////////////////////////////////////

class utils(object):
  """ @brief general purpose utilities """

  @staticmethod
  def load(stream, Loader=yaml.Loader, object_pairs_hook=OrderedDict):
    """ @brief load yamlfile as ordered dictionary. """

    class OrderedLoader(Loader):
      pass
    def construct_mapping(loader, node):
      loader.flatten_mapping(node)
      return object_pairs_hook(loader.construct_pairs(node))
    OrderedLoader.add_constructor(
      yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, construct_mapping)
    return yaml.load(stream, OrderedLoader)

  @staticmethod
  def rm_suffix_slash(instr):
    nstr = re.sub(r"//", "/", instr)
    pstr = instr
    while nstr != pstr:
      pstr = nstr
      nstr = re.sub(r"//", "/", nstr)
    return nstr

  # @reference: https://stackoverflow.com/a/2135920
  @staticmethod
  def chunkify(arr, n):
    return [arr[i::n] for i in range(n)]

  @staticmethod
  def rm_dups_unordered(arr):
    return list(set(arr))

  @staticmethod
  def rm_dups_ordered(arr):
    from collections import OrderedDict
    return list(OrderedDict.fromkeys(arr))

  @staticmethod
  def getenv(name):
    with with_general_exception(fmt.error("Environment variable: '{}' does not exist.".format(name))):
      return os.environ[name]

  @staticmethod
  def isdir(path):
    if not os.path.isdir(path):
      raise DeployerYamlError(fmt.error('Invalid directory path: {}'.format(path)))

  @staticmethod
  def isfile(path):
    if not os.path.isfile(path):
      raise DeployerYamlError(fmt.error('Invalid filepath: {}'.format(path)))

  @staticmethod
  def stdoutfile(filename):
    print()
    with open(filename, "r") as file:
      for line in file:
        print(line, end=' ')

  @staticmethod
  def filter_unique_file_lines(filename):
    """
    @brief filters a file to contain only unique file lines.

    :param filename: filename containing lines for filter
    """

    # read only unique lines
    lines = OrderedDict.fromkeys(open(filename, "r").readlines())
    # write back only unique lines
    file = open(filename, "w").writelines(lines)

  class constant(object):
    """
    @brief setup constant parent class

    :raises DeployerYamlError: attempting to set any class variable
    """

    def __setattr__(self, *_):
      raise header.DeployerYamlError(header.fmt.error('Cannot redefine a constant variable.'))

# //////////////////////////////////////////////////////////////////////////////
# @brief Deployer Configuration Settings
# //////////////////////////////////////////////////////////////////////////////

class path():
  """ @brief global shared deployer path settings """

  TOP    = utils.rm_suffix_slash(utils.getenv("DEPLOYER_PATH"))
  BIN    = utils.rm_suffix_slash(utils.getenv("DEPLOYER_SCRIPTS"))
  BOOKS  = utils.rm_suffix_slash(utils.getenv("DEPLOYER_BOOKS_PATH"))
  EXPORT = utils.rm_suffix_slash(utils.getenv("DEPLOYER_EXPORT_FILEPATH"))
  BASHRC = utils.rm_suffix_slash(utils.getenv("DEPLOYER_BASHRC_FILEPATH"))
  EXTEND = utils.rm_suffix_slash(utils.getenv("DEPLOYER_BOOKS_EXTEND_PATH"))
  HOME   = utils.rm_suffix_slash(utils.getenv("HOME"))

  @classmethod
  def validate(cls):
    # validate the inputs: yaml deployer search path
    utils.isdir(path.TOP)
    utils.isdir(path.BIN)
    utils.isdir(path.BOOKS)
    utils.isdir(path.EXTEND)
    # utils.isdir(path.EXPORT)
    utils.isdir(path.HOME)

class config():
  """ @brief global shared configuration settings """

  PARALLELIZE_MATCHES_JOBS = int(utils.getenv("DEPLOYER_PARALLELIZE_MATCHES_JOBS"))
  WS_NAME = utils.getenv("DEPLOYER_WS_NAME")
