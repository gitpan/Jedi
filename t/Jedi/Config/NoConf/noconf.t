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

my $noconf = use_module('t::lib::Config::App')->new;
is $noconf->jedi_env, 'development', 'env by default is development';
is_deeply $noconf->jedi_config, {}, 'no conf has no config';

done_testing;
