import os, sys

# setup global directories
RUNTESTS_DIR = os.path.abspath(os.path.dirname(__file__))
UNIT_DIR = os.path.join(RUNTESTS_DIR, 'unit')
PHASE_DIR = os.path.join(RUNTESTS_DIR, 'phase')

def print_paths():
  print (RUNTESTS_DIR)
  print (UNIT_DIR)
  print (PHASE_DIR)
