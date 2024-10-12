import sys, os, re, argparse, glob
from deployer import phaser, repl, extend, header
import multiprocessing, time
from collections import OrderedDict

class Deployer(object):
  """
  @brief deployer, prepare and process all matched yaml's phase sections.
  """

  def __init__(self, args, yaml_path, extend_path):
    self.args = args
    self.yaml_path = yaml_path
    self.extend_path = extend_path

  def preview(self, sections):
    """
    @brief print section title prompt

    :param sections: resulting deployer sections
    """

    header.stdout.subtitle('Found the following sections to run:\n')
    for yamlfile, section in list(sections.items()):
      for match in list(section.items()):
        header.stdout.btext("* perform all *") if match[0] == '' else header.stdout.btext( match[0] )
        for phase, cmds in match[1]:
          if phase != match[0]: header.stdout.text('\t-> {}'.format(phase))
          if self.args.verbose:
            for cmd in cmds: print(( '\t-> {} '.format(cmd)))
            header.stdout.newline()
    header.stdout.newline()

  def get_book_paths(self, path, yamls):
    """
    @brief finds all yamls in the default yaml deploy config path

    :param path: filepath to search for yamls
    :param yamls: recursive list of yamls found to parse
    """

    for root, subdirs, files in os.walk(path):
      # append all the files
      yamls.extend( [ "{0}/{1}".format(root, f) for f in files if f.endswith(".yaml") ])
      for subdir in subdirs:
        self.get_book_paths("{0}/{1}".format(root, subdir), yamls)
    return yamls

  def match_section(self, yamls, sections):
    """
    @brief find for a matching section in the given yaml file.

    :param yamls: a given set of yamls to parse
    :param sections: resulting deployer sections
    """

    for yaml in yamls:
      if self.args.verbose:
        header.stdout.text("Searching for section in yaml: {}".format(yaml))

      # load the script, script is formatted as a yaml as a ordered dictionary
      with open(yaml, 'r') as fo:
        script = header.utils.load(fo)

      # extend the yaml script (i.e. search through extend paths)
      extender = extend.Extend(self.extend_path, script)
      script = extender.traverse(script)

      # get all the available phases from the given deployerbook yaml
      phases = phaser.flatten(script)

      # find the sections that match in the phases
      match = None
      try:
        match = phaser.sections(phases, self.args.sections)
        sections[yaml] = match
      except header.DeployerYamlError:
        pass  # silence raised error -- just means no section was found in yaml

    # return the found sections from the yamlfile (or None)
    return sections

  def find_sections(self):
    """
    @brief find the sections, parallelized, in a given set of yamls

    :param args: given user parse-arg arguments
    """

    sections = {}  # initial sections

    # given a specific yaml file -- traverse only that yaml
    if self.args.yaml is not None:
      # given yaml file path, must match section only in that yaml
      books = [[ self.args.yaml ]]

    # not given a specific yaml file -- traverse all possible yaml files in yaml dir path
    else:
      books = self.get_book_paths(self.yaml_path, [])
      if not books: # raise failure if no books found
        raise header.DeployerYamlError(header.fmt.error("Could not find any matching deployerbook yamls."))

      # filtering filepath issues
      books = [b.replace('//', '/') for b in books] # replace the double slashes
      books = header.utils.rm_dups_unordered(books) # remove duplications
      # chunkify books to parallelize
      books = header.utils.chunkify(books, header.config.PARALLELIZE_MATCHES_JOBS)

    # parallelize searching for section matches, in all yaml files
    jobs = []
    manager = multiprocessing.Manager()
    sections = manager.dict()
    for yamls in books:
      p = multiprocessing.Process(target=self.match_section, args=(yamls, sections))
      jobs.append(p)
      p.start()

    # join all the multiprocess jobs
    for job in jobs: job.join()

    # return the resulting matched sections
    return sections

  def _export(self):
    """
    @brief export the deployer's sections for command line tab-completions matches

    :param args: given user parse-arg arguments
    """

    # find all sections that match (with optional to parallelize to speed up search)
    sections = self.find_sections()

    # get the fullpath filename
    filename = "{}/{}.cmpl".format(header.path.EXPORT, self.args.export)

    # create an empty file
    if not self.args.append:
      filedir = os.path.dirname(filename)
      # create the directory, if not created
      if not os.path.isdir(filedir):
        os.makedirs(filedir)
      open(filename, "w+").close()

    # write the section results to the export file
    with open(filename, "a" if self.args.append else "w+" ) as file:
      # process all the sections
      for yaml, section in list(sections.items()):
        for match in list(section.items()):
          for phase, cmds in match[1]:
            if phase != match[0]:
              # filter any duplicated (side-by-side) sections
              phase = phaser.phase_filter_unique(phase)
              # filter out any given phases
              phase = phaser.phase_filter(phase, self.args.filters)
              # do not add in sections that are not ignored
              if any(ignore in phase for ignore in self.args.ignore): continue
              # filter (again, after filter) any duplicated (side-by-side) sections
              phase = phaser.phase_filter_unique(phase)
              # write to file
              print(phase, file=file)

    # filter out any duplicated lines
    header.utils.filter_unique_file_lines(filename)
    if self.args.verbose:
      header.utils.stdoutfile(filename)

  def _deployer(self):
    """
    @brief phaser main entrypoint, similar to main, focused on execution.

    :param args: given user parse-arg arguments
    """

    header.stdout.title("Play Deployer Books")
    header.stdout.text("...finding deployerbook matches")

    # -- find deployerbooks yamls & sections to execute --

    sections = self.find_sections()

    # check for failures -- no section was found
    if not sections:
      raise header.DeployerYamlError(
        header.fmt.error('Invalid section arguments: {}'.format(self.args.sections)))

    # print to screen all sections to run
    self.preview(sections)

    # return if preview -- do not perform the tasks
    if self.args.preview: return

    # -- traverse sections --

    # given the multiple deployerbooks sections, iterate over each section
    for yamlfile, section in list(sections.items()):
      # iterate over a specific match in the section
      for match in list(section.items()):
        # console print
        header.stdout.subtitle('Section: {} \n'.format( "perform all" if match[0] == '' else match[0] ) )
        # get the phase name and associated terminal commands for that phase
        for phase, cmds in match[1]:
          header.stdout.btext('Phase: {} \n'.format(phase))

          # execute the phase's terminal commands using repl interface
          logs = repl.run_session(cmds, phase, yamlfile, self.args)

          # get the duration of the phase
          duration = sum(l['duration'] for l in logs)
          header.stdout.bcoltext('Phase: {} took {:.2f} s. \n\n'.format(phase, duration), header.BLUE)

# //////////////////////////////////////////////////////////////////////////////
# @brief deployer main entrypoints
# //////////////////////////////////////////////////////////////////////////////

class main(object):
  """ @brief meta class, for any main entrypoint calls from scripts. """

  @staticmethod
  def export(yaml_path, extend_path, args):
    """
    @brief export the deployer's sections for command line tab-completions matches

    :param yaml_path: top level yaml path to search for starting point yamls
    :param args: given user parse-arg arguments
    :param extend_path: relative extended path to file to extend
    """
    cli = Deployer(args, yaml_path, extend_path)
    cli._export()

  @staticmethod
  def deployer(yaml_path, extend_path, args):
    """
    @brief phaser main entrypoint

    :param args: given user parse-arg arguments
    :param yaml_path: top level yaml path to search for starting point yamls
    :param extend_path: relative extended path to file to extend
    """

    cli = Deployer(args, yaml_path, extend_path)
    cli._deployer()

