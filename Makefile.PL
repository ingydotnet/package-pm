# This use lib statement technically is not required for normal usage of
# inc::Package, and technically it is not required here. But having it avoids
# subtle bugs that can arise during development and give me a headache.
use lib 'lib';

# This line does all the normal stuff. It invokes pkg/makefile.pl to do any
# other stuff you want to add.
use inc::Package;

# But you still put requires statements in here (and anything else that needs
# to run at installation time).
requires 'Module::Install' => '1.01';
requires 'Mouse';
requires 'MouseX::App::Command';
