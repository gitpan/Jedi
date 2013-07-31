#
# This file is part of Jedi
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Jedi::App;

# ABSTRACT: Jedi App

use strict;
use warnings;

our $VERSION = '0.05';    # VERSION

use Import::Into;
use Module::Runtime qw/use_module/;

sub import {
    my $target = caller;
    use_module('Moo')->import::into($target);
    $target->can('with')->('Jedi::Role::App');
    return;
}

1;

__END__

=pod

=head1 NAME

Jedi::App - Jedi App

=head1 VERSION

version 0.05

=head1 DESCRIPTION

This module allow you to define apps. Apps is plug above roads, and with receive the end of the path (without the road).

You can reused easily apps, like admin panel, or anything, and plug it into any based road you want.

	package MyApps;

	use Jedi::App;
	use JSON;

	sub jedi_apps {
		my ($jedi) = @_;

		$jedi->get('/', $jedi->can('index'));
		$jedi->get('/env', $jedi->can('display_env'));
		$jedi->get(qr{/aaa/}, $jedi->can('aaa'));

		return;
	}

	sub index {
		my ($jedi, $request, $response) = @_;
		$response->status("200");
		$response->body("Hello World !");
		return 1;
	}

	sub display_env {
		my ($jedi, $request, $response) = @_;
		$response->status('200');
		$response->body(to_json($request->env));
		return 1;
	}

	sub aaa {
		my ($jedi, $request, $response) = @_;
		$response->status(200);
		$response->body("AAA !");
	}

	1;

If this is plug with :

	$jedi->road('/test');

This will return :

	/test      # Hello World !
	/test/     # Hello World !
	/test/env  # JSON of env variables
	/test/env/ # JSON of env variables

And also the regexp works

	/test/helloaaaworld # AAA !

=head1 METHODS

=head2 import

This module is equivalent into your package to :

	package MyApps;
	use Moo;
	with "Jedi::Role::App";

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
