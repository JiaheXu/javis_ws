# this file isn't well done at all. Eventually this needs to be re-written.

import pexpect, os, sys, re, time, getpass, re, traceback
# ssh session for repl
from pexpect import replwrap
from pexpect.pxssh import pxssh
from pexpect.replwrap import REPLWrapper, PEXPECT_PROMPT, PEXPECT_CONTINUATION_PROMPT
from deployer import header

# //////////////////////////////////////////////////////////////////////////////
# using subprocess32 (has bug fixes) instead of subprocess
# ref: https://github.com/google/python-subprocess32
# //////////////////////////////////////////////////////////////////////////////
import sys, os
if os.name == 'posix' and sys.version_info[0] < 3:
  try:
    import subprocess32 as subprocess
    from subprocess32 import CalledProcessError
  except ImportError as exc:
    import subprocess
    from subprocess import CalledProcessError
else:
  # non posfix or py3
  import subprocess
  from subprocess import CalledProcessError

# //////////////////////////////////////////////////////////////////////////////
# @brief ALL THIS NEEDS TO BE CLEANED UP...future TODO
# //////////////////////////////////////////////////////////////////////////////
class SHELL(object):
  DEPLOY_DEFAULT_BINARY = "deployer "
  DEPLOY_DEFAULT_PATH="~/{}/".format(header.config.WS_NAME)

  # ////////////////////////////////////////////////////////////////////////////
  # @brief connection session manager
  # ////////////////////////////////////////////////////////////////////////////
  class session(object):
    # default exceptions
    class SessionError(Exception):
      def __init__(self, message):
        header.stdout.error("{0}:\n{1}".format(type(self).__name__, message))

    # @brief open a subprocess
    @staticmethod
    def open(binary, verbose=True):
      binary_process = None
      try:
        # verbose output
        fp = None
        if (not verbose):
          fp = open(os.devnull, "w")
        # load the env
        env = os.environ.copy()
        # open the process
        header.stdout.minorsubtitle("\nBinary to execute: \n")
        header.stdout.text("{}\n".format(binary))
        binary_process = subprocess.Popen(binary, shell=True, env=env, stdout=fp, stderr=fp)
      except CalledProcessError as err:
        print(( "Error running " + binary + ": \n" + err.output))
        return False
      # failed to start binary
      if binary_process is None:
        raise SessionError("Failed to start process {}".format(binary))
      return binary_process

    # @brief terminate subprocess
    @staticmethod
    def close(process):
      while (process.returncode is None):
        process.send_signal(subprocess.signal.SIGINT)
        # process.terminate()
        time.sleep(1)
        process.poll()
      process.terminate()

    # @brief terminate subprocess and all its children
    @staticmethod
    def close_children(p):
      import psutil
      while (p.returncode is None):
        process = psutil.Process(p.pid)
        for sub_process in process.children(recursive=True):
          sub_process.send_signal(subprocess.signal.SIGINT)
        # wait for children to terminate
        p.wait()
        p.terminate()

    # @brief terminate subprocess and all its children
    @staticmethod
    def run(binary):
      binary.communicate()
      while (binary.returncode is None):
        binary.send_signal(subprocess.signal.SIGINT)
        time.sleep(1)
        binary.poll()

    # @brief run binary callback
    @staticmethod
    def run_binary(str_prepare):
      binary = SHELL.session.open(str_prepare)
      SHELL.session.run(binary)
      # SHELL.session.close(binary)
      return binary

    # @brief get duration of a function
    @staticmethod
    def run_and_time(fn):
      start = time.time()
      binary = fn()
      return time.time()-start, binary.returncode


  class IMPORT(object):
    KEY = "+import"
    TAG = staticmethod(lambda cmd: SHELL.IMPORT.KEY in cmd) # get the tag

    @staticmethod
    def get(imports):
      if SHELL.IMPORT.KEY not in imports: return
      # found key, expand path
      file = imports.split(SHELL.IMPORT.KEY)[1]
      # split to gen the env var-value pair
      return file.split(":")

    # TODO: check for input errors...
    @staticmethod
    def process(commands):
      processed = []
      for idx in range(len(commands)):
        cmd = commands[idx]
        if SHELL.IMPORT.KEY in cmd:
          name, value = SHELL.IMPORT.get(cmd)
          filepath = os.path.join(header.path.BOOKS, "{}.yaml".format(value))
          # add all sections at current index
          with open(filepath, 'r') as fo:
            script = header.utils.load(fo)
            processed.extend(script)
        else:
          processed.append(cmd)
      return processed

  class LOCAL(object):
    KEY = "+local"
    TAG = staticmethod(lambda cmd: SHELL.LOCAL.KEY in cmd) # get the tag

    # TODO: check for input errors...
    @staticmethod
    def process(commands):
      if SHELL.LOCAL.KEY not in commands: return commands
      # remove the local tag
      commands.remove(SHELL.LOCAL.KEY)
      # find any remotes tags
      remotes = [ cmd for cmd in commands if SHELL.SSH.TAG(cmd) ]
      # return the commands, with remotes filtered
      return [a for a in commands if a not in remotes ]

  class ENV(object):
    KEY = "+env:"
    TAG = staticmethod(lambda cmd: SHELL.ENV.KEY in cmd) # get the tag

    @staticmethod
    def get(envstr):
      if SHELL.ENV.KEY not in envstr: return
      # found key, expand path
      envstr = envstr.split(SHELL.ENV.KEY)[1]
      # split to gen the env var-value pair
      return envstr.split("=")

    # TODO: check for input errors...
    @staticmethod
    def process(commands):
      """ load environment variable before docker or remote shell command """
      envvars = [ cmd for cmd in commands if SHELL.ENV.TAG(cmd) ]
      # go through all given environment variables
      for env in envvars:
        name, value = SHELL.ENV.get(env)
        # expand value, if value is a nested environment variable
        value = os.path.expandvars(value)
        # set the environment variable, pre-repl
        os.environ[name] = value

      # return the commands, with env filtered
      return [a for a in commands if a not in envvars ]

  # ////////////////////////////////////////////////////////////////////////////
  # @brief create a ssh connection
  # ////////////////////////////////////////////////////////////////////////////
  class SSH(object):
    PXSSH = "bash"
    TAG = staticmethod(lambda cmd: '+ssh' in cmd) # get the tag

    # @brief ssh login exceptions
    class LoginFailure(Exception):
      def __init__(self, message):
        header.stdout.error("Traceback:")
        traceback.print_exc()
        header.stdout.error(message)

    # @brief ssh connection exception
    class SSHUserDeployerYamlError(Exception):
      def __init__(self, message):
        header.stdout.error("{0}:\n{1}".format(type(self).__name__, message))

    # @brief helper -- re search
    @staticmethod
    def re_search(pattern, search_str):
      if re.search(pattern, search_str):
        return str(re.search(pattern, search_str).group(1))
      raise SHELL.SSH.SSHUserDeployerYamlError(
        "Configurations for '+tag' not set correctly. Please, see help for more information.")

    def __init__(self, sshd):
      self.sshd = sshd

    def __eq__(self, other):
      if isinstance(other, str):
        return "ssh:{}".format(other.lower().strip()) in self.sshd.lower().strip()

    # @brief parse a string into its 'ssh' options
    @staticmethod
    def ssh_alias(sshd, verbose=True):
      """ parse the ssh command string into hostname, username values """

      # split the string into args
      ssh_opts = sshd.split(":")

      # minimal options not set
      if (len(ssh_opts) < 2) or (len(ssh_opts) > 5):
        raise SHELL.SSH.SSHUserDeployerYamlError(
          "\t '+ssh' tag in yaml configuration, does not have correct number of arguments.\n"
          "\t Please see help or readme for more information.")

      # parse non connection ssh options
      deploy_path = None
      last = lambda lst: len(lst) - 1
      if "}" not in ssh_opts[last(ssh_opts)]: deploy_path = ssh_opts[last(ssh_opts)]

      # parse connection ssh options
      ssh_conn = SHELL.SSH.re_search('\{(.*)\}', sshd)

      return ssh_conn

    # @brief parse a string into its 'ssh' options
    @staticmethod
    def parse(sshd, verbose=True):
      """ parse the ssh command string into hostname, username values """

      # split the string into args
      ssh_opts = sshd.split(":")

      # minimal options not set
      if (len(ssh_opts) < 2) or (len(ssh_opts) > 5):
        raise SHELL.SSH.SSHUserDeployerYamlError(
          "\t '+ssh' tag in yaml configuration, does not have correct number of arguments.\n"
          "\t Please see help or readme for more information.")

      # parse non connection ssh options
      deploy_path = None
      last = lambda lst: len(lst) - 1
      if "}" not in ssh_opts[last(ssh_opts)]: deploy_path = ssh_opts[last(ssh_opts)]

      # parse connection ssh options
      ssh_conn = SHELL.SSH.re_search('\{(.*)\}', sshd).split(":")
      if (len(ssh_conn) < 2) or (len(ssh_conn) > 3):
        raise SHELL.SSH.SSHUserDeployerYamlError(
          "\t '+ssh' tag in yaml configuration, does not have correct number of connection arguments.\n"
          "\t Please see help or readme for more information.")

      # set the conn options
      username = ssh_conn[0]
      hostname = ssh_conn[1]
      rsa_id = None
      if len(ssh_conn) > 2: rsa_id = ssh_conn[2]

      if verbose:
        # print ssh tag args
        print(( "\thost: {}".format(hostname)))
        print(( "\tusername: {}".format(username)))
        if rsa_id is not None: print(( "\tkey path: {}".format(rsa_id)))
        if deploy_path is not None: print(( "\tdeploy ws path: {}".format(deploy_path)))

      # parsed ssh options
      return hostname, username, rsa_id, deploy_path

    # //////////////////////////////////////////////////////////////////////////
    # @brief create a zsh shell session (over ssh connection)
    # //////////////////////////////////////////////////////////////////////////
    class zsh(object):
      # @brief prepare the session for connection
      @staticmethod
      def prepare(sshd, force_key=False):
        """ prepare the ssh, zsh shell command """
        ssh_prepare = ""  # spawn command str.
        deploy_path = None
        # prepare all ssh connections
        for session in sshd:
          header.stdout.subsubtitle("ssh connection...")

          # uses ssh config file
          ssh_prepare += " ssh {} ".format(SHELL.SSH.ssh_alias(session))

        return ssh_prepare, deploy_path

      # @brief session execution
      @staticmethod
      def session(binary_str):
        # get the duration of the docker execution
        binary = None
        from functools import partial
        duration, ret = SHELL.session.run_and_time(partial(SHELL.session.run_binary, binary_str))
        return duration, ret

    # //////////////////////////////////////////////////////////////////////////
    # @brief create a bash shell session (over ssh connection)
    # //////////////////////////////////////////////////////////////////////////
    class bash(object):
      # @brief prepare the session for connection
      @staticmethod
      def session(sshd):
        # create the pxssh shell session
        shell = pxssh(timeout=None, echo=False)
        spawn_ssh = True  # use initial session
        # go through every ssh session
        for session in sshd:
          # print nice user friendly "connecting to ssh" message
          header.stdout.subsubtitle("ssh connection...")
          # prepare the ssh login
          hostname, username, rsa_id, deploy_path = SHELL.SSH.parse(session)
          # password-less
          if rsa_id is not None:
            shell.login(hostname.strip(), username.strip(), ssh_key=rsa_id.strip(), sync_multiplier=0.01, spawn_local_ssh=spawn_ssh)
          # password
          else:
            password = getpass.getpass()
            shell.login(hostname.strip(), username.strip(), password.strip(), sync_multiplier=0.01, spawn_local_ssh=spawn_ssh)
          spawn_ssh = False
          header.stdout.subsubtitle("ssh connection established.\n")
        # return the spawn session
        shell.sendline()
        return shell

  # ////////////////////////////////////////////////////////////////////////////
  # @brief create a docker shell session (over ssh connection)
  # ////////////////////////////////////////////////////////////////////////////
  class DOCKER(object):
    TAG = staticmethod(lambda cmd: '+docker' in cmd)
    TAG_I = staticmethod(lambda cmd: '+diexec' in cmd)  # interactive docker

    # @brief default exceptions
    class DockerUserDeployerYamlError(Exception):
      def __init__(self, message):
        header.stdout.error("{0}:\n{1}".format(type(self).__name__, message))

    # @brief prepare the session for connection
    @staticmethod
    def prepare(sshd, docker, section, yamlfile, verbose ):
      container, l_exec_cmds, r_exec_cmds = SHELL.DOCKER.parse(docker)
      # TODO, pre & post docker exec

      # replace the yamlfile with a correct username
      reg = "(?<=%s).*?(?=%s)" % ("/home/", "/{}/".format(header.config.WS_NAME))
      r = re.compile(reg,re.DOTALL)
      yamlfile = r.sub("/developer/", yamlfile)

      # create the docker exec command str. ...careful, not sure if below works everywhere.
      docker_prepare = """
        docker exec -w {0} -u developer {1} bash -c " source {2} && {3} -s {4} --local {5}" """.format(
          "/home/developer/{}/".format(header.config.WS_NAME),
          container,
          "~/{}".format(header.path.BASHRC),
          SHELL.DEPLOY_DEFAULT_BINARY,
          section,
          "-v" if verbose else ""
      )

      # prepare the ssh command
      ssh_prepare, deploy_path = SHELL.SSH.zsh.prepare(sshd, force_key=True)
      if ssh_prepare: docker_prepare = "{0} << EOF\n {1} \nEOF\n ".format(ssh_prepare, docker_prepare)

      # return the prepared docker command to run
      return docker_prepare

    # @brief session execution
    @staticmethod
    def session(binary_str):
      # get the duration of the docker execution
      binary = None
      from functools import partial
      duration, ret = SHELL.session.run_and_time(partial(SHELL.session.run_binary, binary_str))
      return duration, ret

    # @brief parse the docker exec commands
    @staticmethod
    def parse(docker):
      """ @brief parse the ssh command string into container, docker exec commands values """

      # split the string into args
      docker_opts = docker.split(":")

      # minimal options not set
      if (len(docker_opts) < 2) or (len(docker_opts) > 4):
        raise SHELL.DOCKER.DockerUserDeployerYamlError(
          "Configurations for '+docker' not set correctly. Please, see help for more information.")

      # initialize before & after commands
      l_exec_cmds, r_exec_cmds = [], []

      # helper, regex pattern search
      def re_search(pattern, search_str):
        if re.search(pattern, search_str):
          return str(re.search(pattern, search_str).group(1))
        raise SHELL.DOCKER.DockerUserDeployerYamlError(
          "Configurations for '+docker' not set correctly. Please, see help for more information.")

      # yaml & exec commands
      if len(docker_opts) == 4:
        pattern = '\{(.*)\}'
        if re.search(pattern, docker_opts[2]):
          # left exec command
          l_exec_cmds = re_search('\{(.*)\}', docker_opts[2]).split(",")

        if re.search(pattern, docker_opts[3]):
          # right exec command
          r_exec_cmds = re_search('\{(.*)\}', docker_opts[3]).split(",")

        # if left and right are both empty, then error when parsing pattern
        empty = lambda lst: len(lst) == 0
        if empty(r_exec_cmds) and empty(l_exec_cmds):
          raise SHELL.DOCKER.DockerUserDeployerYamlError(
            "Configurations for '+docker' not set correctly. Please, see help for more information.")

      # 3 args not allowed, must add in empty left or right and fill in one of them, or leave both out
      elif len(docker_opts) == 3:
        raise SHELL.DOCKER.DockerUserDeployerYamlError(
          "Configurations for '+docker' not set correctly. Please, see help for more information.")

      # return container, yaml commands, exec commands
      return docker_opts[1], l_exec_cmds, r_exec_cmds
