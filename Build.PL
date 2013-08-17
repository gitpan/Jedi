
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Jedi Web Framework",
  "dist_author" => [
    "celogeek <me\@celogeek.com>"
  ],
  "dist_name" => "Jedi",
  "dist_version" => "0.13",
  "license" => "perl",
  "module_name" => "Jedi",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "B::Hooks::EndOfScope" => 0,
    "CGI::Cookie::XS" => 0,
    "CGI::Deurl::XS" => 0,
    "CHI" => 0,
    "Carp" => 0,
    "Config::Any" => 0,
    "FindBin" => 0,
    "HTTP::Body" => 0,
    "Import::Into" => 0,
    "Module::Runtime" => 0,
    "Moo" => 0,
    "Moo::Role" => 0,
    "Path::Class" => 0,
    "YAML::XS" => 0,
    "autobox" => 0,
    "perl" => "5.010",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "HTTP::Request::Common" => 0,
    "JSON" => 0,
    "Plack::Test" => 0,
    "Scalar::Util" => 0,
    "Slurp" => 0,
    "Test::More" => "0.94",
    "Test::Most" => 0,
    "perl" => "5.004"
  }
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  my $tr = delete $module_build_args{test_requires};
  my $br = $module_build_args{build_requires};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
