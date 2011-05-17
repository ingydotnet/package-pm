# This is the Package bootstrapping module.
# It works something like inc::Module::Install.
# This code should only be loaded in an author environment.
package inc::Package;
$VERSION = '0.10';
{
    package main;
    use Package::Bootstrap;
}

1;
