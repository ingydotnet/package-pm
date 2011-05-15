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

my $plugins_file = 'pkg/plugins.pl';
my $makefile = 'pkg/makefile.pl';

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
    # If $SELF is not set, this module was not actually called for.
    return unless $SELF;

    $SELF->_install_bin;

    if ($SELF->is_admin and -e $makefile) {
        require $plugins_file if -e $plugins_file;
        open MF, $makefile or die;
        my $mf = do { local $/; <MF> };
        eval "package main; $mf; 1" or die $@;

        $SELF->clean_files('MANIFEST MANIFEST.SKIP');
    }

    $SELF->all_from($main::PM)
        unless $SELF->name;
    $SELF->WriteAll;

    # We generate a MANIFEST.SKIP and add things to it.
    # We add pkg/, because that should only contain author stuff.
    # We add author only M::I plugins, so they don't get distributed.
    if ($SELF->is_admin) {
        eval "use Module::Install::ManifestSkip; 1" or die $@;
        $SELF->manifest_skip;

        open MS, '>>', 'MANIFEST.SKIP' or die;
        # XXX Hardcoded author list for now. Need to change this.
        print MS <<'...';
^pkg/
^inc/Module/Install/ManifestSkip.pm$
^inc/Module/Install/ReadmeFromPod.pm$
^inc/Module/Install/Stardoc.pm$
...
        close MS;

        $SELF->_write_plugins_file;
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

sub _write_plugins_file {
    my ($self) = @_;
    return unless -d 'pkg';
    my @inc;
    File::Find::find(sub {
        return unless -f $_ and $_ =~ /\.pm$/;
        push @inc, $File::Find::name;
    }, 'inc');
    open PF, '>', $plugins_file or die;
    print PF join '', map {
        s!inc[\/\\](.*)\.pm$!$1!;
        s!/+!::!g;
        "require $_;\n";
    } @inc;
    print PF "1;\n";
    close PF;
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
