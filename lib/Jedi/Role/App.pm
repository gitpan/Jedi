#
# This file is part of Jedi
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Jedi::Role::App;

# ABSTRACT: Jedi App Role

use Moo::Role;
our $VERSION = '0.05';    # VERSION
use Jedi::Helpers::Scalar;
use CHI;
use Carp qw/carp croak/;

has '_jedi_routes'  => ( is => 'ro', default => sub { {} } );
has '_jedi_missing' => ( is => 'ro', default => sub { [] } );
has '_jedi_routes_cache' => ( is => 'lazy', clearer => 1 );

sub _build__jedi_routes_cache {
    return CHI->new(
        driver    => 'RawMemory',
        datastore => {},
        max_size  => 10_000
    );
}

sub _jedi_routes_push {
    my ( $self, $which, $path, $sub ) = @_;
    croak "method invalid : only support GET/POST/PUT/DELETE !"
        if $which !~ /^(?:GET|POST|PUT|DELETE)/x;
    croak "path invalid !" if !defined $path;
    croak "sub invalid !"  if ref $sub ne 'CODE';
    $path = $path->full_path if ref $path ne 'Regexp';
    push @{ $self->_jedi_routes->{$which} }, [ $path, $sub ];
    $self->_clear_jedi_routes_cache;
    return;
}

sub get {
    my ( $self, $path, $sub ) = @_;
    return $self->_jedi_routes_push( 'GET', $path, $sub );
}

sub post {
    my ( $self, $path, $sub ) = @_;
    return $self->_jedi_routes_push( 'POST', $path, $sub );
}

sub put {
    my ( $self, $path, $sub ) = @_;
    return $self->_jedi_routes_push( 'PUT', $path, $sub );
}

sub del {
    my ( $self, $path, $sub ) = @_;
    return $self->_jedi_routes_push( 'DELETE', $path, $sub );
}

sub missing {
    my ( $self, $sub ) = @_;
    croak "sub invalid !" if ref $sub ne 'CODE';

    push( @{ $self->_jedi_missing }, $sub );
    $self->_clear_jedi_routes_cache;
    return;
}

sub response {
    my ( $self, $request, $response ) = @_;

    my $path   = $request->path;
    my $routes = $self->_jedi_routes->{ $request->env->{REQUEST_METHOD} };
    my $methods;

    if ( my $cache_routes = $self->_jedi_routes_cache->get($path) ) {
        $methods = $cache_routes;
    }
    else {
        $methods = [];
        if ( ref $routes eq 'ARRAY' ) {
            for my $route_def (@$routes) {
                my ( $route, $sub ) = @$route_def;
                if ( ref $route eq 'Regexp' ) {
                    push @$methods, $sub if $path =~ $route;
                }
                else {
                    push @$methods, $sub if $path eq $route->full_path;
                }
            }
        }

        @$methods = @{ $self->_jedi_missing } if !scalar @$methods;

        $self->_jedi_routes_cache->set( $path => $methods );
    }

    for my $meth (@$methods) {
        last if !$self->$meth( $request, $response );
    }

    return $response;
}

1;

__END__

=pod

=head1 NAME

Jedi::Role::App - Jedi App Role

=head1 VERSION

version 0.05

=head1 DESCRIPTION

This role is to apply to your Moo module.

   use Moo;
   with 'Jedi::Role::App';

You should use the L<Jedi::App> module.

=head1 METHODS

=head2 get

Define a GET method.

	$jedi->get("/", sub{...});

=head2 post

Define a POST method.

	$jedi->post("/", sub{...});

=head2 put

Define a PUT method.

	$jedi->put("/", sub{...});

=head2 del

Define a DEL method.

	$jedi->del("/", sub{...});

=head2 missing

If no route matches, all the missing method is executed.

	$jedi->missing(sub{...});

=head2 response

This will solve the route, and run all the method found.

If none is found, we run all the missing methods.

The route continue until a "false" response it sent. That should always mean an error.

	$jedi->response($request, $response);

=head1 ROUTES

=head2 GET/POST/PUT/DELETE

All the methods, take a route, and a sub.

The route can be a scalar (exact match) or a regexp.

The sub take L<Jedi::App>, a L<Jedi::Request> and a L<Jedi::Response>.

Each sub should fill the Response based on the Request.

The return code should be "1" if everything goes fine, to let other matching route to apply their changes.

If the return is "0" or undef (false), the route stop and return the response.

You should only use the bad return if something goes wrong.

You can have multiple time the same route catch (thought regexp, and exact match). Each one receive a response, and pass this
response to the next sub.

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
