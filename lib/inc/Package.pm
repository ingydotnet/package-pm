# This is the package bootstrapping module.
# It works like inc::Module::Install.
# It should only be installed on author's perl installs.
package inc::Package;

warn "================================> inc::Package";
package main;
use Package::Bootstrap;

my $target_file = 'inc/Package.pm';
unlink $target_file;
my $source_file = $INC{'Package/Bootstrap.pm'} or die;
Module::Install::Admin->copy($source_file, $target_file);

1;
