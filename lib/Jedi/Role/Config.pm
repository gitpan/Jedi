#
# This file is part of Jedi
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Jedi::Role::Config;

# ABSTRACT: Easy load of config file by env

use Moo::Role;
our $VERSION = '0.11';    # VERSION
use Path::Class;
use FindBin qw/$Bin/;
use Config::Any;

has 'jedi_app_root' => ( is => 'lazy' );

sub _build_jedi_app_root {
    my ($self) = @_;
    my $config_files = $self->jedi_config_files->[0];

    return defined $config_files ? file($config_files)->dir : dir($Bin);
}

has 'jedi_config_files' => ( is => 'lazy' );

sub _build_jedi_config_files {
    my ($self) = @_;

    my $env = $self->jedi_env;

    my $curdir    = dir($Bin);
    my $main_file = "config";
    my $env_file  = "" . file( 'environments', $env );

    my @files;
    my %look;
    while ( !exists $look{$curdir} ) {
        $look{$curdir} = 1;
        for my $ext ( Config::Any->extensions ) {
            my $full_main_file = file( $curdir, $main_file . '.' . $ext );
            my $full_env_file  = file( $curdir, $env_file . '.' . $ext );
            push @files, $full_main_file if -f $full_main_file;
            push @files, $full_env_file  if -f $full_env_file;
            last if @files;
        }
        last if @files;
        $curdir = $curdir->parent;
    }
    return \@files;
}

has 'jedi_env' => ( is => 'lazy', clearer => 1 );

sub _build_jedi_env {
    return $ENV{'JEDI_ENV'} // $ENV{'PLACK_ENV'} // 'development';
}

has 'jedi_config' => ( is => 'lazy', clearer => 1 );

sub _build_jedi_config {
    my ($self) = @_;

    my $files = $self->jedi_config_files;
    return {} if !@$files;

    my $config = Config::Any->load_files( { files => $files, use_ext => 1 } );
    my $config_merged = {};
    for my $c ( map { values %$_ } @$config ) {
        %$config_merged = ( %$config_merged, %$c );
    }
    return $config_merged;

}

1;

__END__

=pod

=head1 NAME

Jedi::Role::Config - Easy load of config file by env

=head1 VERSION

version 0.11

=head1 DESCRIPTION

We will try to load the config into the current directory and try all parents.

The sub env is loaded using the jedi_env.

Ex: 

  PLACK_ENV = test

Load
  config.*
  environments/test.*

The config is merged together, so the "test" file replace keys from the main config.

Ex:

  config.yml

     test: 1
     hello: 2

  environments/test.yml

     test: 2
     world: 1

The jedi_config is set to :

   {
	 test => 2,
	 hello => 2,
	 world => 1,
   }

=head1 ATTRIBUTES

=head2 jedi_app_root

This attribute set the root of your app based on the config files.

It try to look for "config.*" or "environments/$jedi_env.*" and set the root app to this.

If nothing found, the root app will be the current dir of the module.

=head2 jedi_config_files

The config files found based on the root apps

=head2 jedi_env

Environment of your jedi app.

It take : JEDI_ENV or PLACK_ENV or set 'development' by default

=head2 jedi_config

Load config from current app dir or any subdir above.

It also take 'environments/$JEDI_ENV' file.

=head1 SEE ALSO

L<Config::Any>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://tasks.celogeek.com/projects/perl-modules-jedi

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by celogeek <me@celogeek.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
