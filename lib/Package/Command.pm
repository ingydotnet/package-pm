##
# name:      Package::Command
# author:    Ingy döt Net <ingy@cpan.org>
# copyright: 2011
# license:   perl

package Package::Command;
use strict;
use warnings;
use Mouse;
extends 'MouseX::App::Cmd';

sub BUILD {
    die "Sorry, this software is still be developed. Hang in there.";
}

package Package::Cmd;
use Mouse;

package Package::Cmd::new;

1;
