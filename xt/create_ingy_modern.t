use Test::More tests => 2;
use strict;

use Cwd 'abs_path';
use lib abs_path 'lib';
use Capture::Tiny 'capture_merged';

$ENV{PATH} = abs_path('bin') . ":$ENV{PATH}";

my $dest = 'xt/foo-pm/';
`rm -fr $dest`;

my $home = $ENV{HOME};
my $cmd = join ' ', qw[
    pkg
    new
    --tagline='Best Foo module ever'
],
    "--from=$ENV{HOME}/src/pkg/perl/ingy-modern",
qw[
    --unit=Foo
    --unit=Foo::Bar
    --git.create=0
], $dest;

my $rc = system($cmd);

`rm -fr $dest/.git`;

if ($rc == 0) {
    pass 'command worked';
}
else {
    fail 'command failed';
    exit;
}

my $diff = capture_merged {
    system("diff -ru xt/foo-expected $dest");
};
if (not length $diff) {
    pass 'new Foo is correct';
    `rm -fr $dest`;
}
else {
    fail 'new Foo does not match expected';
    die $diff;
}
