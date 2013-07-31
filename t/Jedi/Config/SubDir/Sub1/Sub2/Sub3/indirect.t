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
use Module::Runtime qw/use_module/;

{
    my $indirect = use_module('t::lib::Config::App')->new;
    is $indirect->jedi_env, 'development', 'env by default is development';
    is_deeply $indirect->jedi_config,
        {
        direct => 2,
        conf   => 'dev',
        },
        'dev conf loaded';
}

for my $env_name (qw/JEDI_ENV PLACK_ENV/) {
    {
        local $ENV{$env_name} = 'prod';
        my $indirect = use_module('t::lib::Config::App')->new;
        is $indirect->jedi_env, 'prod', 'env is now prod';
        is_deeply $indirect->jedi_config, { direct => 1, },
            'prod conf loaded';
    }

    {
        local $ENV{$env_name} = 'test';
        my $indirect = use_module('t::lib::Config::App')->new;
        is $indirect->jedi_env, 'test', 'env is now prod';
        is_deeply $indirect->jedi_config,
            {
            direct => 1,
            conf   => 'test',
            },
            'test conf loaded';
    }
}

done_testing;
