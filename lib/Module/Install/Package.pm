##
# name:      Module::Install::Package
# abstract:  Package Support for Module::Install
# author:    Ingy döt Net <ingy@cpan.org>
# copyright: 2011
# license:   perl

package Module::Install::Package;
use strict;
use warnings;
use 5.008003;
use base 'Module::Install::Base';
our $VERSION = '0.10';

use File::Find;

# If a Makefile.PL calls 'pkg', save $self, and wait until the END.
my $SELF;
sub pkg {
    my ($self) = ($SELF) = @_;
}

# Take a guess at the primary .pm and .pod files for 'all_from', and friends.
# Put them in global vars in the main:: namespace.
BEGIN {
    package main;
    use vars qw($PM $POD);
    $PM = '';
    my $high = 999999;
    File::Find::find(sub {
        return unless /\.pm$/;
        my $name = $File::Find::name;
        my $num = ($name =~ s!/+!/!g);
        if ($num < $high) {
            $high = $num;
            $PM = $name;
            ($POD = $PM) =~ s/\.pm/.pod/ or die;
        }
    }, 'lib');
}

# Run author commands from pkg/makefile.pl.
# Run other basics.
sub END {
    return unless $SELF;
    my $makefile = 'pkg/makefile.pl';
    if ($SELF->is_admin and -e $makefile) {
        open MF, $makefile or die;
        my $mf = do { local $/; <MF> };
        eval "package main; $mf; 1" or die $@;

        $SELF->clean_files('MANIFEST MANIFEST.SKIP');
    }

    $SELF->_install_bin;
    $SELF->all_from($main::PM)
        unless $SELF->name;
    $SELF->WriteAll;

    if ($SELF->is_admin) {
        eval "use Module::Install::ManifestSkip; 1" or die $@;
        $SELF->manifest_skip;
        open MS, '>>', 'MANIFEST.SKIP' or die;
        print MS <<'...';
^pkg/
^inc/Module/Install/ManifestSkip.pm$
^inc/Module/Install/ReadmeFromPod.pm$
^inc/Module/Install/Stardoc.pm$
...
        close MS;
    }
}

sub _install_bin {
    my ($self) = @_;
    return unless -d 'bin';
    my @bin;
    File::Find::find(sub {
        return unless -f $_;
        push @bin, $File::Find::name;
    }, 'bin');
    $self->install_script($_) for @bin;
}

1;

=head1 SYNOPSIS

    use inc::Module::Install; pkg;

=head1 DESCRIPTION

This Module::Install plugin attempts to make your C<Makefile.PL> as small as
possible. Every C<Makefile.PL> can be an indentical one liner.

=head1 STATUS

This module is at a proving concepts phase. It is not ready for general use.

=head1 CONCEPTS

Some of the things it is doing:

  * Showing how to make a small, static Makefile.PL
  * Removing author-only plugins from the dist.
  * Removing the need for MANIFEST related files.

All the author specifics go under the pkg/ directory.
