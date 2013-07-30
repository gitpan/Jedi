#
# This file is part of Jedi
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package t::lib::request;
use Jedi::App;
use JSON;
use Slurp;

sub jedi_app {
    my ($jedi) = @_;

    $jedi->get( '/', $jedi->can('handle_params') );
    $jedi->post( '/', $jedi->can('handle_params') );
    $jedi->put( '/', $jedi->can('handle_params') );

    $jedi->get( '/file', $jedi->can('handle_uploads') );
    $jedi->post( '/file', $jedi->can('handle_uploads') );
    $jedi->put( '/file', $jedi->can('handle_uploads') );

    $jedi->get( '/cookie', $jedi->can('handle_cookies') );
}

sub handle_params {
    my ( $jedi, $request, $response ) = @_;
    my $p = $request->params;
    $response->status(200);
    $response->body( to_json($p) );
    return 1;
}

sub handle_uploads {
    my ( $jedi, $request, $response ) = @_;
    my $u  = $request->uploads;
    my $fn = $u->{myTestFile}->{tempname};
    my $ct = defined $fn ? slurp($fn) : '';

    $response->status(200);
    $response->body($ct);

    return 1;
}

sub handle_cookies {
    my ( $jedi, $request, $response ) = @_;
    my $cookies = $request->cookies;
    $response->status(200);
    $response->body( to_json($cookies) );
}
1;
