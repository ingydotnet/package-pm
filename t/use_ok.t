use Test::More tests => 2;

die "@INC";
use_ok 'Package';
use_ok 'Module::Install::Package';
