#!/usr/local/bin/perl

package cmpl_header;
use Exporter;

# //////////////////////////////////////////////////////////////////////////////
# @brief export modules
# //////////////////////////////////////////////////////////////////////////////

our @ISA= qw( Exporter );

# these CAN be exported.
our @EXPORT_OK = qw(
  @_javis
  @_tools
);

# these are exported by default.
our @EXPORT = qw(
  @_javis
  @_tools
);

our (
  @_javis,
  @_tools,
);

# //////////////////////////////////////////////////////////////////////////////
# @brief general arrays for [TAB] autocompletion
# //////////////////////////////////////////////////////////////////////////////
@_javis       = ( "deployer", "ansible", "setup", "tools", "help" );
@_tools       = ( "ssh.probe" );
# @_git         = ( "sync", "status", "clean", "rm", "reset", "pull", "help" );
# @_git_status  = ( "autonomy", "cameras", "common", "drivers", "loam" );
# @_git_sync    = ( "autonomy", "cameras", "common", "drivers", "loam" );
