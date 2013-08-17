#
# This file is part of Jedi
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Jedi::Request;

# ABSTRACT: Jedi Request

use Moo;

our $VERSION = '0.13';    # VERSION

use HTTP::Body;
use CGI::Deurl::XS 'parse_query_string';
use CGI::Cookie::XS;

has 'env' => ( is => 'ro', required => 1 );

has 'path' => ( is => 'ro', required => 1 );

has 'params' => ( is => 'lazy' );

sub _build_params {
    my ($self) = @_;
    my $method = $self->env->{REQUEST_METHOD};
    if ( $method eq 'POST' || $method eq 'PUT' ) {
        return $self->_body->param;
    }
    else {
        return parse_query_string( $self->env->{QUERY_STRING} ) // {};
    }
}

has 'uploads' => ( is => 'lazy' );

sub _build_uploads {
    my ($self) = @_;
    my $method = $self->env->{REQUEST_METHOD};
    if ( $method eq 'POST' || $method eq 'PUT' ) {
        return $self->_body->upload;
    }
    else {
        return {};
    }
}

has 'cookies' => ( is => 'lazy' );

sub _build_cookies {
    my ($self) = @_;
    return CGI::Cookie::XS->parse( $self->env->{HTTP_COOKIE} // '' );
}

has '_body' => ( is => 'lazy' );

sub _build__body {
    my ($self) = @_;

    my $type   = $self->env->{'CONTENT_TYPE'}   || '';
    my $length = $self->env->{'CONTENT_LENGTH'} || 0;
    my $io     = $self->env->{'psgi.input'};
    my $body = HTTP::Body->new( $type, $length );
    $body->cleanup(1);

    while ($length) {
        $io->read( my $buffer, ( $length < 8192 ) ? $length : 8192 );
        $length -= length($buffer);
        $body->add($buffer);
    }

    return $body;
}

sub scheme {
    my ($self) = @_;
    my $env = $self->env;

    return
           $env->{'X_FORWARDED_PROTOCOL'}
        || $env->{'HTTP_X_FORWARDED_PROTOCOL'}
        || $env->{'HTTP_X_FORWARDED_PROTO'}
        || $env->{'HTTP_FORWARDED_PROTO'}
        || $env->{'psgi.url_scheme'}
        || $env->{'PSGI.URL_SCHEME'}
        || '';
}

sub port {
    my ($self) = @_;
    my $env = $self->env;

    return $env->{'SERVER_PORT'};
}

sub host {
    my ($self) = @_;
    my $env = $self->env;

    return
           $env->{'HTTP_X_FORWARDED_HOST'}
        || $env->{'X_FORWARDED_HOST'}
        || $env->{'HTTP_HOST'}
        || '';
}
1;

__END__

=pod

=head1 NAME

Jedi::Request - Jedi Request

=head1 VERSION

version 0.13

=head1 DESCRIPTION

This object is pass through the route, as a second params. (self, request, response).

You can get data from it, to generate your response

=head1 ATTRIBUTES

=head2 env

The environment variable, as it received from PSGI

=head2 path

The end of the path_info, without the road.

Ex:
	road("/test"), route("/me") # so /test/me/ will give the path /me/

=head2 params

If method is POST or PUT, it will parse the body, and extract the params.

Otherwise it parse the QUERY_STRING.

It always return an HASH, with:

	key => Scalar // [ARRAY of Values]

Ex:

	a=1&a=2&a=3&b=4&b=5&b=6&c=1

You receive:

	a => [1,2,3]
	b => [4,5,6]
	c => 1

=head2 uploads

Return the file uploads.

For a request like test@test.txt, the form is : 

   	test => {
	    filename   "test.txt",
        headers    {
            Content-Disposition   "form-data; name="test"; filename="test.txt"",
            Content-Type          "text/plain"
        },
        name       "test",
        size       13,
        tempname   "/var/folders/_1/097rrrdd2s5dwqgd7hp6nlx00000gn/T/X4me5HO7L_.txt"
   	}

Ex with curl :

	curl -F 'test@test.txt' http://localhost:5000/post

You can read then the tempname file to get the content. When the request is sent back, the file is automatically removed.

See <HTTP::Body> for more details.

=head2 cookies

Parse the HTTP_COOKIE, and return an Hash of array

Ex:

	a=1&b&c; b=4&5&6; c=1

You receive:

	a => [1,2,3]
	b => [4,5,6]
	c => [1]

=head1 METHODS

=head2 scheme

Return the scheme from proxied proto or main proto

=head2 port

Return server port

=head2 host

Return the proxied host or the main host

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
