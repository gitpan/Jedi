#!perl
#
# This file is part of Jedi
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use Test::Most 'die';
use HTTP::Request::Common;
use Plack::Test;
use Jedi;
use JSON;
use FindBin qw/$Bin/;

my $jedi = Jedi->new();
$jedi->road( '/', 't::lib::request' );

test_psgi $jedi->start, sub {
    my ($cb) = @_;
    {
        my $res = $cb->( GET '/' );
        is $res->code,    200,  'status is correct';
        is $res->content, '{}', 'status is empty, no params';
    }

    {
        my $res = $cb->( GET '/?a=1&a=2&b=1' );
        is $res->code, 200, 'status is correct';
        is_deeply from_json( $res->content ), { a => [ 1, 2 ], b => 1 },
            '... and params is correct';
    }

    {
        my $res = $cb->( POST '/?a=1&a=2&b=1' );
        is $res->code, 200, 'status is correct';
        is_deeply from_json( $res->content ), {},
            '... and params is empty (not a post)';
    }

    {
        my $res = $cb->( POST '/', [ a => 1, a => 2, b => 1 ] );
        is $res->code, 200, 'status is correct';
        is_deeply from_json( $res->content ), { a => [ 1, 2 ], b => 1 },
            '... and params is correct';
    }

    {
        my $res = $cb->( PUT '/?a=1&a=2&b=1' );
        is $res->code, 200, 'status is correct';
        is_deeply from_json( $res->content ), {},
            '... and params is empty (not a post)';
    }

    {
        my $req = POST '/', [ a => 1, a => 2, b => 1 ];
        $req->method('PUT');

        my $res = $cb->($req);
        is $res->code, 200, 'status is correct';
        is_deeply from_json( $res->content ), { a => [ 1, 2 ], b => 1 },
            '... and params is correct';
    }

    {
        # do a POST request, with GET (post file into the content)
        my $req = POST '/file',
            Content_Type => 'form-data',
            Content =>
            [ myTestFile => [ $Bin . "/../data/hello_world.txt" ], ];
        $req->method('GET');

        my $res = $cb->($req);
        is $res->code, 200, 'status is correct';
        is $res->content, '';
    }

    {
        # post the file, and get it back through content
        my $res = $cb->(
            POST '/file',
            Content_Type => 'form-data',
            Content =>
                [ myTestFile => [ $Bin . "/../data/hello_world.txt" ], ]
        );
        is $res->code,    200,             'status is correct';
        is $res->content, 'Hello World !', '... and tiny content is correct';
    }

    {
        # post the file, and get it back through content
        my $res = $cb->(
            POST '/file',
            Content_Type => 'form-data',
            Content =>
                [ myTestFile => [ $Bin . "/../data/hello_world_big.txt" ], ]
        );
        is $res->code, 200, 'status is correct';
        is $res->content,
            join( "\n", map {"Hello World !"} ( 1 .. 650 ) ) . "\n",
            '... and big content is correct';
    }

    {
        my $req = POST '/file',
            Content_Type => 'form-data',
            Content =>
            [ myTestFile => [ $Bin . "/../data/hello_world.txt" ], ];
        $req->method('PUT');

        # post the file, and get it back through content
        my $res = $cb->( $req );
        is $res->code,    200,             'status is correct';
        is $res->content, 'Hello World !', '... and tiny content is correct';
    }

    {
        my $req = POST '/file',
            Content_Type => 'form-data',
            Content =>
            [ myTestFile => [ $Bin . "/../data/hello_world_big.txt" ], ];
        $req->method('PUT');

        # post the file, and get it back through content
        my $res = $cb->($req);
        is $res->code, 200, 'status is correct';
        is $res->content,
            join( "\n", map {"Hello World !"} ( 1 .. 650 ) ) . "\n",
            '... and big content is correct';
    }

    {
        # simulate empty file
        my $req = POST '/file',
            Content_Type => 'form-data',
            Content =>
            [ myTestFile => [ $Bin . "/../data/hello_world.txt" ], ];
        $req->content_length(0);
        my $res = $cb->($req);
        is $res->code,    200, 'status is correct';
        is $res->content, '',  '... and tiny content is correct';
    }

    {
        #Test cookies
        my $res = $cb->( GET '/cookie' );
        is $res->code,    200,  'status is correct';
        is $res->content, '{}', '... and content is correct';

    }

    {
        #Test cookies
        my $res = $cb->( GET '/cookie', 'Cookie' => 'a=1' );
        is $res->code, 200, 'status is correct';
        is_deeply from_json( $res->content ), { a => [1] },
            '... and content is correct';

    }

    {
        #Test cookies
        my $res = $cb->( GET '/cookie', 'Cookie' => 'a=1&2; b=1' );
        is $res->code, 200, 'status is correct';
        is_deeply from_json( $res->content ), { a => [ 1, 2 ], b => [1] },
            '... and content is correct';

    }

    {
        #Test cookies
        my $res = $cb->( GET '/cookie', 'Cookie' => ' ' );
        is $res->code, 200, 'status is correct';
        is_deeply from_json( $res->content ), {},
            '... and content is correct';

    }

    {
        #Test jedi default env
        my $res = $cb->( GET '/jedi_env' );
        is $res->code,           200,           'status is correct';
        is_deeply $res->content, 'development', '... and content is correct';

    }
};

{
    local $ENV{PLACK_ENV} = 'test';
    test_psgi $jedi->start, sub {
        my ($cb) = @_;
        {
            #Test jedi default env
            my $res = $cb->( GET '/jedi_env' );
            is $res->code,           200,    'status is correct';
            is_deeply $res->content, 'test', '... and content is correct';
        }
        }
}

{
    # test scheme/port/env
    test_psgi $jedi->start, sub {
        my ($cb) = @_;
        {
            my $req = GET 'http://sck.to/scheme';
            my $res = $cb->($req);
            is $res->code,           200,    'status is correct';
            is_deeply $res->content, 'http', '... and content is correct';
        }
        {
            my $req = GET 'http://sck.to/port';
            my $res = $cb->($req);
            is $res->code,           200,  'status is correct';
            is_deeply $res->content, '80', '... and content is correct';
        }
        {
            my $req = GET 'http://sck.to/host';
            my $res = $cb->($req);
            is $res->code,           200,      'status is correct';
            is_deeply $res->content, 'sck.to', '... and content is correct';
        }
        }
}

done_testing;