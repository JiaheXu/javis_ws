#!/usr/bin/env python
import argparse

# Parse arguments
def parse_args():
    parser = argparse.ArgumentParser(
      description='Rosinstall Updater -- manually update by giving a local name (using -l) and the version (using -v),'
                  'or automatically update by giving project name (using -p).')
    parser.add_argument(
      '-l', '--localname', type=str, default='', dest='local_name',
      help='specify local_name that needs to be updated')
    parser.add_argument(
      '-v', '--version', type=str, metavar='version', default='', dest='version', help='specify version of the git')
    parser.add_argument(
      '-p', '--project', type=str, metavar='project', default='', dest='project', help='specify the project folder, followed by repo to be automatically updated, i.e. basestation or basestation.thirparty')
    args = parser.parse_args()
    return args

# run deploy as script
if __name__ == "__main__":
  # add full path
  import os, sys
  try:
    import deploy
  except ImportError:
    sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
  # run deploy
  from deployer import update_script

  ROOT = "../../../rosinstall_/"
  EXTENSION = ".rosinstall"
  ROOT_GIT = "../../../"

  # Parsing arguments and passing it into update_script.main()
  args = parse_args()
  local_name = args.local_name
  version = args.version
  project = args.project

  ##### throw an exception here ###

  update_script.main(ROOT, EXTENSION, ROOT_GIT,
                     project = project,
                     local_name = local_name,
                     version = version)
