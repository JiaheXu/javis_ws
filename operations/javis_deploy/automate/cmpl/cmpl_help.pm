#!/usr/local/bin/perl#!/usr/local/bin/perl

package cmpl_deployer;
use Exporter;
use FindBin;
use cmpl_utils;
use Env;

# //////////////////////////////////////////////////////////////////////////////
# @brief export modules
# //////////////////////////////////////////////////////////////////////////////
our @ISA= qw( Exporter );

# these CAN be exported.
our @EXPORT_OK = qw(
  $_help_title
  %_help_repository
  %_help_robots
  format_help_str
  create_help
  get_main_help
  get_catkin_help
  get_docker_help
  get_workspace_help
);

# these are exported by default.
our @EXPORT = qw(
  $_help_title
  %_help_repository
  %_help_robots
  format_help_str
  create_help
  get_main_help
  get_catkin_help
  get_docker_help
  get_workspace_help
);

# //////////////////////////////////////////////////////////////////////////////
# @brief setup various help messages
# //////////////////////////////////////////////////////////////////////////////

our $_help_title = "About: 01... == JAVIS ==
About: 02... Enabling Enhanced Situational Awareness and Human Augmentation through Efficient Autonomous Systems
About: 03...
About: 04... HowTo:
About: 05...  - Press 'Tab' once, to preview a list of completed word options.
About: 06...  - Input a tab-complete word, from the preview list of completed words.
About: 07...  - Press '.', TAB to preview the next list of next available deployer actions.
About: 08...  - Press SPACE, TAB to show the help message and preview words (for your current completion match).
About: 09... * MAKE SURE THERE IS NO WHITESPACE WHEN YOU SELECT THE NEXT KEYWORD (i.e. press backspace to show tab-complete list)
";

our $_help_flags = "
About: 11...
About: 12... == Optional Flags ==
About: 13...
About: 14...   -p           : preview the deployer commands that will be run
About: 15...   -verbose     : show the exact (verbose) bash commands that will run
About: 16...
About: 17... == Your Tab-Completed Word Options Are ==
About: 18...
";

our %_help_robots = (
  local       => "directly on any payload, basestation or laptop (simulation) host.",
  pt001       => "rc car, orin payload 001.",
  pt002       => "rc car, orin payload 002.",
  pt003       => "rc car, orin payload 003.",
  spot001     => "spot, orin payload 001.",
);

our %_help_repository = (
  common      => "set of common tools, including forks of thirdparty libraries.",
  autonomy    => "core autonomy stack libraries, for all robot types.",
  estimation  => "state estimation libraries, such as LOAM.",
  drivers     => "various drivers, from robot to sensor payload.",
  cameras     => "camera interfaces, such as gstreamer ROS interface.",
  sim         => "simulation stack libraries.",
);

our %_help_catkin = (
  catkin_deps_build    => "build the dependency (ex. common) catkin workspace",
  catkin_deps_clean    => "clean the dependency (ex. common) catkin workspace",
  catkin_core_build    => "build the core catkin workspace",
  catkin_core_clean    => "clean the catkin workspace",
);

our %_help_catkin_core = (
  catkin_core_build    => "build the core catkin workspace",
  catkin_core_clean    => "clean the catkin workspace",
);

our %_help_catkin_deps = (
  catkin_deps_build    => "build the dependency (ex. common) catkin workspace",
  catkin_deps_clean    => "clean the dependency (ex. common) catkin workspace",
);

our %_help_docker = (
  docker_make             => "build docker images",
  docker_shell_start      => "start docker containers",
  docker_shell_stop       => "stop docker containers",
  docker_shell_rm         => "remove docker containers",
  docker_registry_push    => "push docker images to remote registry",
  docker_registry_pull    => "pull docker images from remote registry",
);

# this is really ugly (listing all the mon ), its OK for now...

our %_help_mon = (
  mon    => "launch the ros modules, using rosmon.",
);

our %_help_mon_workspaces = (
  mon_roscore         => "start a roscore, assessable by all containers.",
  mon_imu             => "start the imu, espon driver.",
  mon_nmea            => "start the nmea driver, to synchronise the veldyne laser data.",
  mon_thermal         => "start the thermal camera driver.",
  mon_mavros          => "start the mavros driver.",
  mon_joy             => "start the joy driver.",
  mon_velodyne        => "start the velodyne laser driver.",
  mon_loam            => "start loam state estimation module.",
  mon_sim             => "start state estimation for simulation testing.",
  mon_local_planner   => "start autonomoy local planner.",
  mon_racecar         => "start racecar simulation.",
  mon_rviz            => "start rviz visualization.",
);

# //////////////////////////////////////////////////////////////////////////////
# @brief create the help messages
# //////////////////////////////////////////////////////////////////////////////

# @brief create help -- internal helper
sub _create_help {
  my %word_description = %{$_[0]};
  my @keyword = @{$_[1]};
  my $_help_msg;
  foreach $word (@keyword) {
    $_help_msg .= format_help_str($word, %word_description);
  }
  return $_help_msg;
}

# -- main --

# @brief create the 'main', tab-completion help message
sub get_main_help {
  @keyword = qw(local pt001 pt002 pt003 spot001);
  return _create_help(\%_help_robots, \@keyword);
}

# -- single robot help --

# @brief create the repository help message
sub get_repository_help {
  @keyword = qw(common autonomy estimation drivers cameras sim);
  return _create_help(\%_help_repository, \@keyword);
}

# -- workspace --

# @brief create the repository help message (merge docker, catkin helps)
sub get_workspace_help {
  my $_help_msg;
  $_help_msg = $_help_msg . get_docker_help();
  $_help_msg = $_help_msg . get_catkin_help();
  $_help_msg = $_help_msg . get_mon_help();
  return $_help_msg;
}

# -- catkin --

# @brief create the 'catkin', tab-completion help message
sub get_catkin_help {
  @keyword = qw(catkin_core_build catkin_core_clean catkin_deps_build catkin_deps_clean);
  return _create_help(\%_help_catkin, \@keyword);
}

# @brief create the 'catkin core', tab-completion help message
sub get_catkin_core_help {
  @keyword = qw(catkin_core_build catkin_core_clean);
  return _create_help(\%_help_catkin_core, \@keyword);
}

# @brief create the 'catkin core', tab-completion help message
sub get_catkin_deps_help {
  @keyword = qw(catkin_deps_build catkin_deps_clean);
  return _create_help(\%_help_catkin_deps, \@keyword);
}

# -- docker --

# @brief create the 'docker', tab-completion help message
sub get_docker_help {
  @keyword = qw(docker_make docker_shell_start docker_shell_stop docker_shell_rm docker_registry_push
    docker_registry_pull);
  return _create_help(\%_help_docker, \@keyword);
}

# @brief create the 'docker registry', tab-completion help message
sub get_docker_registry_help {
  @keyword = qw(docker_registry_push docker_registry_pull);
  return _create_help(\%_help_docker, \@keyword);
}

# @brief create the 'docker shell', tab-completion help message
sub get_docker_shell_help {
  @keyword = qw(docker_shell_start docker_shell_stop docker_shell_rm);
  return _create_help(\%_help_docker, \@keyword);
}

# -- mon --

# @brief create the general 'mon', tab-completion help message
sub get_mon_help {
  @keyword = qw(mon);
  return _create_help(\%_help_mon, \@keyword);
}

# @brief create the 'mon.common', tab-completion help message
sub get_mon_common_help {
  @keyword = qw(mon_roscore);
  return _create_help(\%_help_mon_workspaces, \@keyword);
}

# @brief create the 'mon.drivers', tab-completion help message
sub get_mon_drivers_help {
  @keyword = qw(mon_imu mon_nmea mon_thermal mon_mavros mon_joy mon_velodyne);
  return _create_help(\%_help_mon_workspaces, \@keyword);
}

# @brief create the 'mon.loam', tab-completion help message
sub get_mon_estimation_help {
  @keyword = qw(mon_loam mon_sim mon_rviz);
  return _create_help(\%_help_mon_workspaces, \@keyword);
}

# @brief create the 'mon.autonomy', tab-completion help message
sub get_mon_autonomy_help {
  @keyword = qw(mon_local_planner);
  return _create_help(\%_help_mon_workspaces, \@keyword);
}

# @brief create the 'mon.sim', tab-completion help message
sub get_mon_simulation_help {
  @keyword = qw(mon_racecar mon_rviz);
  return _create_help(\%_help_mon_workspaces, \@keyword);
}

# //////////////////////////////////////////////////////////////////////////////
# @brief general wrappers
# //////////////////////////////////////////////////////////////////////////////

# @brief convert keywords, with '_' as deliminator to '.' as deliminator.
sub format_help_str {
  my ($_name, %_hash ) = @_;
  # convert any underscores to dots
  (my $fmt_name = $_name) =~ s/\_/\./g;
  # format output help description print
  return sprintf("%-30s %00s \n", "$fmt_name", $_hash{"$_name"} );
}

# @brief create full tab-completion help message
sub create_help {
  my ($_append_msg) = @_;
  # append the header & body help message
  my $_help_msg = $_help_title . $_help_flags . $_append_msg;
  # crate newline, or wont show help
  newline();
  return $_help_msg;
}
