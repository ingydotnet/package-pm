##
# name:      Package
# abstract:  Acmeist Module Packaging Toolchain
# author:    Ingy döt Net <ingy@cpan.org>
# copyright: 2011
# license:   perl

package Package;
use 5.008003;

our $VERSION = '0.11';

1;

=head1 SYNOPSIS

From the command line:

    > pkg new --perl=package --module=Foo::Bar foo-bar-pm

=head1 DESCRIPTION

Package is a toolchain for packaging module distributions. Not just Perl
modules, but modules from many different languages.

This package installs a command line tool called C<pkg>, that can be used to
create and maintain open source module packages in several programming
languages.

=head1 MORE DOCUMENTATION

Coming soon.

=head1 STATUS

This is a early, "proving concepts", release. Keep out.
