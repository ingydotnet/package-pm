use Test::More tests => 2;
use strict;

use Cwd 'abs_path';
use lib abs_path 'lib';
use Capture::Tiny 'capture_merged';

$ENV{PATH} = abs_path('bin') . ":$ENV{PATH}";

my $dest = 'xt/foo-pm/';
`rm -fr $dest`;

my $rc = system("pkg new --from=$ENV{HOME}/src/pkg/perl/ingy-modern --module=Foo --module=Foo::Bar $dest");

`rm -fr $dest/.git`;

if ($rc == 0) {
    pass 'command worked';
}
else {
    fail 'command failed';
    exit;
}

my $diff = capture_merged {
    system("diff -ru $dest xt/foo-expected");
};
if (not length $diff) {
    pass 'new Foo is correct';
    `rm -fr $dest`;
}
else {
    fail 'new Foo does not match expected';
    die $diff;
}
