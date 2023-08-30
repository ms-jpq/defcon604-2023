#!/usr/bin/env -S -- perl -CASD -w

use Cwd;
use English;
use File::Basename;
use autodie;
use strict;
use utf8;

my $path = Cwd::abs_path(__FILE__);
chdir dirname(__FILE__);

print "HELO :: VIA -- $PROGRAM_NAME\n";

system( 'bat', '--', $path )
  && croak $CHILD_ERROR;
