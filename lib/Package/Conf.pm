##
# name:      Package::Conf
# abstract:  Config Class for Package
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011
package Package::Conf;
use Mouse;

use Cwd;
use File::Spec;
use IO::All;
use YAML::XS;
use XXX;

has src_dir => (is => 'ro');
has dir_stack => (is => 'rw');
has stash => (is => 'rw');
has manifest => (is => 'rw');

sub BUILD {
    my ($self) = @_;
    my $home = Cwd::cwd;
    my $dir = $self->src_dir;
    my @dirs;
    while (1) {
        $dir = Cwd::abs_path($dir);
        chdir $dir or die "'$dir' does not exist";
        die "$dir is not a directory" unless -d $dir;
        my $conf_file = 
            -f 'pkg.conf' ? 'pkg.conf' : ''
            or die "$dir contains no pkg.conf file";
        unshift @dirs, $dir;
        my $conf = YAML::XS::LoadFile($conf_file);
        last if $conf->{pkg_top_level_dir};
        my @dir = File::Spec->splitdir($dir) or die;
        pop @dir;
        $dir = File::Spec->catdir(@dir) or die;
    }

    my $stash = {};
    my $manifest = {};
    for (my $i = 0; $i < @dirs; $i++) {
        my $dir = $dirs[$i];
        chdir $dir;
        File::Find::find(sub {
            if (-f 'pkg.conf' and $File::Find::dir ne $File::Find::topdir) {
                $File::Find::prune = 1;
                return;
            }
            if ($i == 0) {
                $stash = Hash::Merge::merge(
                    $stash, YAML::XS::LoadFile('pkg.conf'),
                );
                $File::Find::prune = 1;
                return;
            }
            if ($File::Find::dir =~ /\.git/) {
                $File::Find::prune = 1;
                return;
            }
            if ($_ eq 'pkg.conf') {
                $stash = Hash::Merge::merge(
                    $stash, YAML::XS::LoadFile('pkg.conf'),
                );
                return;
            }
            return if -d;
            $manifest->{$File::Find::name} = Cwd::abs_path($_);
        }, '.');
    }
    $self->manifest($manifest);
    $self->stash($stash);
    chdir $home or die;
}

1;
