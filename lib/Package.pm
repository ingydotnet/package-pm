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

#------------------------------------------------------------------------------#
package Package;

our $VERSION = '0.14';

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

has tagline => (
    is => 'ro',
    isa => 'Str',
    default => sub { '' },
    required => 0,
    documentation => 'Tagline for package',
);

sub execute {
    my ($self, $opt, $args) = @_;
    my $pkg_name = shift(@$args) || '';
    
    my $to = io($pkg_name || '.')->absolute;

    $pkg_name ||= do {
        my $cwd = Cwd::cwd;
        $cwd =~ s!.*/!!;
        $cwd;
    };

    my $stash = $self->conf->stash;
    $stash->{pkg}{name} = $pkg_name;
    $stash->{tagline} = $self->tagline;

    if ($to->exists) {
        die "$to is not empty" if not $to->empty;
    }
    else {
        $to->assert->mkdir;
    }
    $to->chdir or die "Can't chdir to $to";
    $stash->{module}{name} = $self->module->[0];

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

    if ($stash->{git}{create}) {
        system("git init; git add .; git commit -m 'First commit'");
        if (my $url = $stash->{git}{origin}) {
            $url =~ s/\%pkg\.name\%/$stash->{pkg}{name}/e;
            system("git remote add origin $url");
        }
        # XXX Check Net::Ping->new->ping("github.com");
        if (my $github = $stash->{git}{github}) {
            my $login = $github->{login};
            my $token = $github->{token};
            my $tagline = $stash->{tagline};
            system(qq{curl -F login=$login -F token=$token https://github.com/api/v2/yaml/repos/create -F name=$pkg_name -F "description=$tagline"});
            system("git push origin master");
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
of programming languages. Perl 5 modules for CPAN, Python modules for PyPI,
Ruby modules for RubyGems, etc.

In truth, pkg is nothing more than a simple way to create a new directory of
starter files, by applying a set of configuration information to a set of file
templates. The information is all completely in your control. You can use
other people's templates or create your own.

=head1 QUICK START

Here's the quick and simple way to get started, assuming you are familiar with
L<cpanm> and C<git>. From the command line:

    > # Go to the directory where you keep your git repos:
    > cd $HOME/src/
    > # Get the base pkg directory:
    > git clone https://github.com/ingydotnet/pkg
    > # Get a basic pkg template. In the case, for a Perl module:
    > git clone https://github.com/ingydotnet/perl-basic-pkg pkg/perl/basic
    > # Edit the conf files appropriately
    > edit pkg/pkg.conf pkg/perl/pkg.conf pkg/perl/basic/pkg.conf
    > # Now create a new perl module in the foo-bar-pm directory
    > pkg new --from=pkg/perl/basic --module=Foo::Bar --module=Foo::Gorch foo-bar-pm
    > # Make another new module!
    > pkg new --from=pkg/perl/basic --module=Bar::Bar bar-bar-pm

That was easy.

=head1 MORE DOCUMENTATION

Coming soon. :)
