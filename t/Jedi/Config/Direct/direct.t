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
use Path::Class;
use FindBin qw/$Bin/;

{
    my $direct = use_module('t::lib::Config::App')->new;
    is $direct->jedi_env, 'development', 'env by default is development';
    is_deeply $direct->jedi_config,
        {
        direct => 2,
        conf   => 'dev',
        },
        'dev conf loaded';
    is $direct->jedi_app_root, dir($Bin),
        '... and the root app is at the same place';
    is_deeply $direct->jedi_config_files,
        [
        file( dir($Bin), 'config.yml' ),
        file( dir($Bin), 'environments', 'development.yml' )
        ],
        '... the conf found is correct';
}

for my $env_name (qw/JEDI_ENV PLACK_ENV/) {

    {
        local $ENV{$env_name} = 'prod';
        my $direct = use_module('t::lib::Config::App')->new;
        is $direct->jedi_env, 'prod', 'env is now prod';
        is_deeply $direct->jedi_config, { direct => 1, }, 'prod conf loaded';
        is $direct->jedi_app_root, dir($Bin),
            '... and the root app is at the same place';
        is_deeply $direct->jedi_config_files,
            [ file( dir($Bin), 'config.yml' ), ],
            '... the conf found is correct';
    }

    {
        local $ENV{$env_name} = 'test';
        my $direct = use_module('t::lib::Config::App')->new;
        is $direct->jedi_env, 'test', 'env is now prod';
        is_deeply $direct->jedi_config,
            {
            direct => 1,
            conf   => 'test',
            },
            'test conf loaded';
        is $direct->jedi_app_root, dir($Bin),
            '... and the root app is at the same place';
        is_deeply $direct->jedi_config_files,
            [
            file( dir($Bin), 'config.yml' ),
            file( dir($Bin), 'environments', 'test.yml' )
            ],
            '... the conf found is correct';
    }

}

done_testing;
