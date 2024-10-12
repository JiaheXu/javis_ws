package cmpl_utils;
use Exporter;


# //////////////////////////////////////////////////////////////////////////////
# @brief export modules
# //////////////////////////////////////////////////////////////////////////////
our @ISA= qw( Exporter );

# these CAN be exported.
our @EXPORT_OK = qw(
  chk_flag
  uniq
  remove_trail_dot
  remove_lead_dot
  openfile
  get_matches_between_delim
  get_btw_delim
  chk_in
  newline
  format_help_str
);

# these are exported by default.
our @EXPORT = qw(
  chk_flag
  uniq
  remove_trail_dot
  remove_lead_dot
  openfile
  get_btw_delim
  get_nbtw_delim
  chk_in
  newline
  format_help_str
);

# //////////////////////////////////////////////////////////////////////////////
# @brief functions
# //////////////////////////////////////////////////////////////////////////////

# @brief check string equalities
sub chk_flag {
  my ($_flag, $_args) = @_;
  $_args =~ m/$_flag/ ? return 1 : return 0;
}

# @brief filter unique strings from array
# @reference: https://perldoc.perl.org/perlfaq4.html#How-can-I-remove-duplicate-elements-from-a-list-or-array%3f
sub uniq {
  my %seen;
  my @unique = grep { ! $seen{ $_ }++ } @_;
  return @unique
}

# @brief remove trailing dot in string
sub remove_trail_dot {
  $_[0]=~ s/\.+$//;
}
# @brief remove leading dot in string
sub remove_lead_dot {
  $_[0]=~ s/^\.+//;
}

# @brief open given filepath, for reading
sub openfile {
  my ($_filename) = @_;

  # my $path_to_file = "$FindBin::Bin/.completion/${_filename}";
  my $path_to_file = "$ENV{DEPLOYER_EXPORT_FILEPATH}/${_filename}";
  my $handle;
  unless (open $handle, "<:encoding(utf8)", $path_to_file) {
    print STDERR "Could not open file '$path_to_file': $!\n";
    return undef
  }
  chomp(@_file = <$handle>);
  unless (close $handle) {
    print STDERR "Failed closing file '$path_to_file': $!\n";
  }
  return @_file;
}

# @brief get the positional match, between deliminiators '_'
sub get_btw_delim {
  my ($_str, $_pos) = @_;

  # get all matches (except suffix)
  my @matches = $_str =~ /([^\_]+)\_/g;

  # get length of matches
  my $_length = scalar(@matches);

  # get the positional match (if given valid positional argument)
  if ($_pos < $_length) { return "@matches[$_pos]"; }

  # get suffix only for any end-of array position
  return $_str =~ /([^\_][^_]+)$/g;
}

# @brief get the number of matches, between deliminiators '_'
sub get_nbtw_delim {
  my ($_str) = @_;

  # get all matches (except suffix)
  my @matches = $_str =~ /([^\_]+)\_/g;

  # get length of matches
  my $_length = scalar(@matches);

  # return number of matches (+1 for last suffix)
  return $_length + 1;
}

# @brief check if element is in array
sub chk_in {
  my ($_param, @_arr) = @_;
  # convert array to hash
  my %params = map { $_ => 1 } @_arr;
  # check if value is in array
  return exists($params{$_param});
}

# @brief print newline
sub newline { print " \n"; }
