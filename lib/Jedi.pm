#
# This file is part of Jedi
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Jedi;

# ABSTRACT: Jedi Web Framework

use Moo;

our $VERSION = '0.04';    # VERSION

use Jedi::Helpers::Scalar;
use Jedi::Request;
use Jedi::Response;

use Module::Runtime qw/use_module/;
use Carp qw/croak/;

has '_jedi_roads'           => ( is => 'ro', default => sub { [] } );
has '_jedi_roads_is_sorted' => ( is => 'rw', default => sub {0} );

sub road {
    my ( $self, $base_route, $module ) = @_;
    $base_route = $base_route->full_path();

    my $jedi = use_module($module)->new();
    croak "$module is not a jedi app" unless $jedi->does('Jedi::Role::App');

    $jedi->jedi_app;

    push( @{ $self->_jedi_roads }, [ $base_route => $jedi ] );
    $self->_jedi_roads_is_sorted(0);
    return;
}

sub response {
    my ( $self, $env ) = @_;

    my $jedi_env = $ENV{PLACK_ENV} // 'development';
    my $sorted_roads = $self->_jedi_roads;
    if ( !$self->_jedi_roads_is_sorted ) {
        $self->_jedi_roads_is_sorted(1);
        @$sorted_roads
            = sort { length( $b->[0] ) <=> length( $a->[0] ) } @$sorted_roads;
    }

    my $path_info = $env->{PATH_INFO}->full_path();
    my $response  = Jedi::Response->new();

    for my $road_def (@$sorted_roads) {
        my ( $road, $jedi ) = @$road_def;
        if ( $path_info->start_with($road) ) {
            return $jedi->response(
                Jedi::Request->new(
                    jedi_env => $jedi_env,
                    env      => $env,
                    path     => $path_info->without_base($road)
                ),
                $response
            );
        }
    }

    return Jedi::Response->new( status => 500, body => 'No road found !' );
}

sub start {
    my ($self) = @_;
    return sub { $self->response(@_)->to_psgi };
}

1;

__END__

=pod

=head1 NAME

Jedi - Jedi Web Framework

=head1 VERSION

version 0.04

=head1 DESCRIPTION

Jedi is another Web Framework, build for easiness to maintain, easy to understand, and NO DSL !

A Jedi script will plug in roads, any Jedi::App you want.

Ex :

   use Jedi;
   my $jedi = Jedi->new

   $jedi->road('/', 'MyApps');
   $jedi->road('/admin', 'MyApps::Admin');

   $jedi->start;

Then your Jedi Apps look likes :

	package MyApps;
	use Jedi::Apps;

	sub jedi_apps {
		my ($jedi) = @_;

		$jedi->get('/', $jedi->can('index'));
		$jedi->get(qr{/env/.*}, $jedi->can('env'));
	}

	sub index {
		my ($jedi, $request, $response) = @_;
		$response->status(200);
		$response->body('Hello World !');
		return 1;
	}

	sub env {
		my ($jedi, $request, $response) = @_;
		my $env = substr($request->path, length("/env/"));
		$response->status(200);
		$response->body("The env : <$env>, has the value <". ($request->env->{$env} // "").">");
		return 1;
	}

	1;

You can also plug multiple time the same route or similar, the response will be fill by each routes.

A route can check the status to see if another route has already do something. Same think for the body.

You can for instance, create a role, with a before "jedi_apps", that init or add body content, and you route, add more stuff.

Or do an after, that add to the routes, additional content.

This is just a start, more will come.

=head1 METHODS

=head2 road

Add a based route to your Jedi Apps

	$jedi->road('/', 'MyApps');
	$jedi->road('/admin', 'MyApps::Admin');

=head2 response

Check the road available based on the current request and call the appropriate Jedi::App module

	my $response = $jedi->response(\%ENV);

The response returned is a L<Jedi::Response>, you can call the to_psgi method to get the status / headers / body

	my ($status, $headers, $body) = $response->to_psgi

=head2 start

Start your jedi apps

At the end of your Jedi script, call the start method.

This feat the psgi format, and should be placed in your app.psgi script.

	$jedi->start

=head1 SEE ALSO

L<Jedi::App>

L<Jedi::Request>

L<Jedi::Response>

=cut

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
