# This module is installed as Package::Bootstrap on an author's machine.
# It gets included as Package.pm in inc/Package.pm in a Perl distribution.
package Package::Bootstrap;

# NOTE: This module gets shipped with CPAN dists so only use Legacy Perl.

package Package;
# Keep a synchonized $VERSION for all parts involved.
$VERSION = '0.10';

# inc::Module::Install won't work unless called from 'main'.
# TODO - Talk to Adam Kennedy about better way to invoke.
package main;

# Invoke a normal Module::Install. No tricks.
use inc::Module::Install;

# Call the 'pkg' function from the 'Module::Install::Package' plugin.
# This is where all the cool magic happens. :)
pkg;

# Make sure 'inc/Package.pm' is up to date
my $target_file = 'inc/Package.pm';
if (-e 'inc/.author' and not -e $target_file) {
    my $source_file = $INC{'Package/Bootstrap.pm'} ||
        $INC{'Package.pm'}
            or die "Can't bootstrap inc::Package";
    Module::Install::Admin->copy($source_file, $target_file);
}

# Be True to the perl!
1;
