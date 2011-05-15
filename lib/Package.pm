##
# name:      Package
# abstract:  Acmeist Module Packaging Toolchain
# author:    Ingy döt Net <ingy@cpan.org>
# copyright: 2011
# license:   perl

package Package;
use 5.008003;

our $VERSION = '0.02';

1;

=head1 DESCRIPTION

Package is a toolchain for packaging module distributions. Not just Perl
modules, but modules from many different languages.

=head1 STATUS

This is a super early, proving concepts, release.

The main thing this module does at this point is offer a Module::Install
plugin called L<Module::Install::Package>.
