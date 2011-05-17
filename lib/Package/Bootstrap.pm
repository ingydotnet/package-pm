# package Package::Bootstrap;

# This module is installed as Package::Bootstrap on an author's machine.
# It gets included as Package.pm in inc/Package.pm in a Perl distribution.
package Package;

# inc::Module::Install won't work unless called from 'main'.
# TODO - Talk to Adam Kennedy about better way to invoke.
package main;

# Invoke a normal Module::Install. No tricks.
use inc::Module::Install;

# Call the 'pkg' function from the 'Module::Install::Package' plugin.
# This is where all the cool magic happens. :)
pkg;

# Be True to the perl!
1;
