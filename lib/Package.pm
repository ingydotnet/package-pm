##
# name:      Package
# abstract:  The Acmeist Module Package Management Tool
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011

use 5.008003;

use Mouse 0.93 ();
use MouseX::App::Cmd 0.08 ();
use Hash::Merge 0.12 ();
use IO::All 0.43 ();
use Template::Toolkit::Simple 0.13 ();
use YAML::XS 0.35 ();

package Package;

our $VERSION = '0.12';

#------------------------------------------------------------------------------#
package Package::Command;
use App::Cmd::Setup -command;
use Mouse;
extends 'MouseX::App::Cmd::Command';

sub validate_args {}

# Semi-brutal hack to suppress extra options I don't care about.
around usage => sub {
    my $orig = shift;
    my $self = shift;
    my $opts = $self->{usage}->{options};
    @$opts = grep { $_->{name} ne 'help' } @$opts;
    return $self->$orig(@_);
};

#-----------------------------------------------------------------------------#
package Package;
use App::Cmd::Setup -app;
use Mouse;
extends 'MouseX::App::Cmd';

use Module::Pluggable
  require     => 1,
  search_path => [ 'Package::Command' ];
Package->plugins;

#------------------------------------------------------------------------------#
package Package::Command::new;
Package->import( -command );
use Mouse;
extends 'Package::Command';

use Cwd 'abs_path';
use IO::All;
use Template::Toolkit::Simple;

use constant abstract => 'Create new module package directory from template';
use constant usage_desc => 'pkg init --from=<dir> --module=<Name> --to=<dir>';

has from => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    documentation => 'Pkg template directory',
);

has module => (
    is => 'ro',
    isa => 'Str',
    isa => 'ArrayRef[Str]',
    documentation => 'Name of new module',
);

sub execute {
    my ($self, $opt, $args) = @_;
    my $to = io(shift(@$args) || '.')->absolute;

    my $stash = $self->conf->stash;

    if ($to->exists) {
        die "$to is not empty" if not $to->empty;
    }
    else {
        $to->assert->mkdir;
    }
    $to->chdir or die "Can't chdir to $to";

    my @special;
    for my $file (sort keys %{$self->conf->manifest}) {
        if ($file =~ /%/) {
            push @special, $file;
            next;
        }
        my $path = $self->conf->manifest->{$file};
        my $template = io($path)->all;
        my $text = tt
            ->path([])
            ->data($stash)
            ->render(\$template);
        io($file)->assert->print($text);
    }

    for my $module (@{$self->module}) {
        $stash->{module}{name} = $module;
        ($stash->{module}{path} = $module) =~ s!::!/!g;
        for my $file (@special) {
            my $path = $self->conf->manifest->{$file};
            my $template = io($path)->all;
            (my $local = $file) =~ s!%module\.path%!$stash->{module}{path}!;
            my $text = tt
                ->path([])
                ->data($stash)
                ->render(\$template);
            io($local)->assert->print($text);
        }
    }

    print "New package '$to' successfully created!\n";
}

#------------------------------------------------------------------------------#
package Package::Command::listvars;
Package->import( -command );
use Mouse;
extends 'Package::Command';

use constant abstract => 'Print list of config variables from template';
use constant usage_desc => 'pkg liastvars --from=<dir>';

has from => (
    is => 'ro',
    isa => 'Str',
    documentation => 'Pkg template directory',
);

sub execute {
    my ($self, $opt, $args) = @_;
    print YAML::XS::Dump($self->get_stash);
}

#------------------------------------------------------------------------------#
package Package::Command;

has _conf => (
    is => 'ro',
    lazy => 1,
    reader => 'conf',
    default => sub {
        require Package::Conf;
        my ($self) = @_;
        Package::Conf->new(
            src_dir => $self->from,
        );
    },
);

1;

=head1 SYNOPSIS

From the command line:

    > pkg help

    > pkg new \
            --from=pkg/perl/module-install \
            --module=Foo::Bar \
            --module=Foo::Bar::Baz \
            foo-bar-pm

=head1 DESCRIPTION

C<pkg> is your tool for creating distributable, modular packages, in a variety
of programming languages.

In some languages, there's more than one way to do it (TMTOWTDI!!). C<pkg>
accounts for that as well. You can often choose from a selection of packaging
styles within a given programming language. You can even easily make your own
styles.

=head1 MORE DOCUMENTATION

Coming soon.

=head1 STATUS

This is an early release. Keep out.
