# this file isn't well done, not readable and most is not necessary. Eventually this needs to be re-written.

import os, pexpect, sys, re, time, tempfile, getpass
# ssh session for repl
from pexpect import replwrap
from pexpect.pxssh import pxssh
from pexpect.replwrap import REPLWrapper, PEXPECT_PROMPT, PEXPECT_CONTINUATION_PROMPT
from deployer import header
from deployer.conn import *

# default exceptions
class UserYamlConfigurationError(Exception):
  def __init__(self, message):
    header.stdout.error("{0}:\n{1}".format(type(self).__name__, message))

# //////////////////////////////////////////////////////////////////////////////
# @brief shell stdout formatters
# //////////////////////////////////////////////////////////////////////////////

class StdoutUTF8(object):
  @staticmethod
  def write(utf8):
    return sys.stdout.write(utf8)
  @staticmethod
  def flush():
    return sys.stdout.flush()

class AnsiEscaper(object):
  """ @brief Ansi escaper, i.e. filter any colors. """

  regex = re.compile(r'(\033)(\[\d+m)')
  def __init__(self, ansi_esc='ANSI_ESC'):
    self.ansi_esc = ansi_esc
  def sub(self, substring, string):
    return re.sub(self.regex, substring, str(string))
  def wrap(self, string):
    substring = lambda match: '$'+self.ansi_esc+match.group(2)
    return self.sub(substring, string)
  def strip(self, string):
    return self.sub('', string)

# //////////////////////////////////////////////////////////////////////////////
# @brief repl handlers
# //////////////////////////////////////////////////////////////////////////////

def create_replwrap(shell, ps1, ps2):
  """ @brief create the repl """

  ansier = AnsiEscaper()  # get the ansi escaper

  # change the prompt to PS1 / PS2
  raw_changer = '{esc}=$(printf "\e") PS1="{ps1}" PS2="{ps2}" PROMPT_COMMAND=""'
  ps_prompt = raw_changer.format(
    esc=ansier.ansi_esc, ps1=ansier.wrap(ps1), ps2=ansier.wrap(ps2))
  # create the repl -- read-eval-print-loops, i.e. iteractive shells
  return replwrap.REPLWrapper(
    cmd_or_spawn = shell,
    orig_prompt = ['\$', '\#'],
    prompt_change = ps_prompt,
    new_prompt = str(ansier.strip(ps1)),
    continuation_prompt = str(ansier.strip(ps2)),
    extra_init_cmd='export PAGER=cat')

def repl_shell(pxssh=[], docker=None):  # rename to remote & docker
  """
  @brief prepare the repl session shell: local or remote over ssh.

  :param remote: the command string from the yaml, to specify the ssh connection.
  :param docker: the command string from the yaml, to specify the docker exec interactive connection.
  """

  # local repl: use a bash shell
  if not pxssh and not docker:
    shell = pexpect.spawn('bash', timeout=None, encoding='utf-8')
    return shell

  # docker interactive repl: use a docker exec session shell
  # **warning**: does not work well, the shell is very difficult to navigate. TODO improve it?
  elif docker:
    # get the ssh for a zsh terminal, wont work with default bash terminal session
    command = SHELL.SSH.zsh.prepare(pxssh)
    command += "'docker exec -it -e xterm=TERM -u developer {} /bin/bash' ".format(docker.split(":")[1])
    shell = pexpect.spawn(command, encoding='utf-8', echo=True, timeout=2, dimensions=(1000,1000))
    shell.sendline()
    shell.interact()  # allow for interactive access
    return shell

  # ssh repl: use a bash shell
  elif pxssh:
    return SHELL.SSH.bash.session(pxssh) # bash session, return the pxssh session for repl run

def start_replwrap(sshd=[], dexec=None):
  """
  @brief start the repl bash shell (local or remote).

  :param sshd: the command string from the yaml, to specify the ssh connection.
  :param dexec: the command string from the yaml, to specify the docker exec interactive connection.
  """

  ps_text = '<deploy>'
  ps1 = header.fmt.ps_format() + ps_text + ' ' + header.DEFAULT
  ps2 = header.fmt.ps_format() + ps_text + '... ' + header.DEFAULT
  # create the repl -- we want to use a local or remote bash shell
  try:
    return create_replwrap(repl_shell(sshd, dexec), ps1, ps2)
  # catch any repl errors
  except pexpect.pxssh.ExceptionPxssh as e:
    raise SHELL.SSH.LoginFailure(str(e))
  except pexpect.exceptions.EOF as e:
    raise SHELL.SSH.LoginFailure(str(e))
  except Exception as e:
    raise SHELL.SSH.LoginFailure(str(e))

def run_replwrap(commands, repl, verbose=True, timeout=-1):
  """ @brief loop through all the commands in the given section and execute them using repl interface """

  # text color filter
  ansier = AnsiEscaper()
  logs = [] # setup output logs from repl
  # iterate through each single command, meaning a single terminal command listed in the yaml file
  for command in commands:
    # set the repl logfile
    repl.child.logfile = StdoutUTF8
    # start timer of command
    start = time.time()
    # run the phase command
    output = repl.run_command(command, timeout=timeout)
    # stop timer of command, get duration
    duration = time.time()-start
    # get the return code
    repl.child.logfile = None
    if command != 'docker rmi -f $(docker images -f "dangling=true" -q) 2&1> /dev/null':
      ansier.strip(repl.run_command('echo $?').strip())
      code = 0
    else:
      code = 0
    # append log
    log = dict( command = command, returned = code, duration = duration, output = output)
    logs.append(log)
    # console print
    header.stdout.text('command finished in {:.2f} s\n'.format(duration, **log))
    # there was an error code, exit early
    if code:
      header.stdout.error(
        '{clr}ABORTING due to exit code: {code}{endc} \n'.format(
          clr=header.RED+header.BOLD, endc=header.DEFAULT, code=code))
      sys.exit(code)
  # done with repl
  repl.child.close()
  return logs

def run_docker_non_repl(sshd, dexec, section, yamlfile, verbose):
  """
  @brief start a popen process (i.e. non-repl) for docker exec command, local or remote connection.

  :param sshd: the command string from the yaml, to specify the ssh connection.
  """

  # prepare the docker command to run
  docker_prepare = SHELL.DOCKER.prepare(sshd, dexec, section, yamlfile, verbose)

  # execute
  duration, code = SHELL.SSH.zsh.session(docker_prepare)
  # if error code is failure, exit
  if code: sys.exit(code)
  # return duration of execution
  return [dict( binary = docker_prepare, returned = code, duration = duration)]


def run_ssh_non_repl(sshd, section, yamlfile, verbose):
  # prepare the ssh command
  ssh_prepare, deploy_path = SHELL.SSH.zsh.prepare(sshd, force_key=True)

  # set the deploy path
  SHELL.DEPLOY_DEFAULT_PATH = deploy_path if deploy_path else SHELL.DEPLOY_DEFAULT_PATH

  # remove the local home prefix from the yamlfile
  yamlfile = yamlfile.replace(header.path.HOME, "~/")

  # prepare the full ssh command, i.e. with bash command
  # ssh_prepare= "{0} << EOF\n cd {1} \n source {2} \n {3} -y {4} -s {5} --local {6} \nEOF\n ".format(
  ssh_prepare= "{0} << EOF\n source {2} \n {3} -s {5} --local {6} \nEOF\n ".format(
    ssh_prepare,
    SHELL.DEPLOY_DEFAULT_PATH,
    "~/{}".format(header.path.BASHRC),
    SHELL.DEPLOY_DEFAULT_BINARY,
    yamlfile,
    "-a" if section == None else section,
    "-v" if verbose else ""
  )

  # execute
  duration, code = SHELL.SSH.zsh.session(ssh_prepare)
  # if error code is failure, exit
  if code: sys.exit(code)
  header.stdout.subtitle("SSH connection done.")
  # return duration of execution
  return [dict( binary = ssh_prepare, returned = code, duration = duration)]

def run_session(commands, section, yamlfile, args):
  """ @brief entrypoint interface: execute the given phase's section commands in terminal. """

  # setup local vars to determine type of execution to do using given user args
  timeout = -1 if not args.timeout else args.timeout
  verbose = False if not args.verbose else args.verbose
  local   = False if not args.local else args.local

  # exit early if no commands are given
  if len(commands) <= 0:
    raise UserYamlConfigurationError("\t No commands given in yaml configuration, Please see help info. \n")

  # setup the type of session
  idx = lambda fn: next(i for i, cmd in enumerate(commands) if fn(cmd))
  # setup getting all ssh connection commands
  sshd_conn = lambda commands : [ c for c in commands if SHELL.SSH.TAG(c) and not ( SHELL.SSH(c) == SHELL.SSH.PXSSH)]

  def remove_tags(commands) :
    """ @brief delete any tagged commands """
    # remove all ssh commands
    for cmd in [ c for c in commands if SHELL.SSH.TAG(c) ]:
      del commands[commands.index(cmd)]
    # remove all docker commands
    if any(SHELL.DOCKER.TAG_I(cmd) for cmd in commands):
      del commands[idx(SHELL.DOCKER.TAG_I)]
    if any(SHELL.DOCKER.TAG(cmd) for cmd in commands):
      del commands[idx(SHELL.DOCKER.TAG)]
    if any(SHELL.ENV.TAG(cmd) for cmd in commands):
      del commands[idx(SHELL.ENV.TAG)]
    return commands

  # remove any remotes tags
  commands = SHELL.LOCAL.process(commands)

  # load environment variable before docker or remote shell command
  commands = SHELL.ENV.process(commands)

  # import any commands from another file
  commands = SHELL.IMPORT.process(commands)

  ## repl: after ssh connected, run non-tagged commands as repl
  if local:
    remove_tags(commands)     # remove any tags
    repl = start_replwrap()   # execute a repl commands, post ssh connection

  ## non-repl: docker
  elif any(SHELL.DOCKER.TAG(cmd) for cmd in commands):
    # execute a zsh shell docker execute command over multi-hop ssh
    return run_docker_non_repl (sshd_conn(commands), commands[idx(SHELL.DOCKER.TAG)], section, yamlfile, verbose )

  ## non-repl: ssh over zsh
  elif (  not any( SHELL.SSH(cmd) == SHELL.SSH.PXSSH for cmd in commands)  and
          any( SHELL.SSH.TAG(cmd) for cmd in commands ) ):
    # execute a zsh shell command over multi-hop ssh
    return run_ssh_non_repl(sshd_conn(commands), section, yamlfile, verbose )

  ## repl: ssh over bash, docker interactive
  elif  ( any(SHELL.SSH.TAG(cmd) for cmd in commands) or
          any(SHELL.DOCKER.TAG_I(cmd) for cmd in commands) ):
    # execute a bash shell command over multi-hop ssh & execute repl commands directly
    repl = start_replwrap (
      sshd = sshd_conn(commands),
      dexec=None if not any(SHELL.DOCKER.TAG_I(cmd) for cmd in commands) else commands[idx(SHELL.DOCKER.TAG_I)])  # TODO
    remove_tags(commands) # remove any tags

  ## repl: local session, no special session tags
  else: repl = start_replwrap()
  ## run the repl session
  return run_replwrap(commands, repl, verbose, timeout)
