#!/usr/bin/env perl

use strict;
use FindBin qw($Bin);
use File::Spec::Functions qw(catfile);

my $autogen_protobuf = catfile($Bin, 'autogen_protobufxs.pl');
my $autogen_thrift = catfile($Bin, 'autogen_thrift.pl');

system($autogen_protobuf) == 0 or die "Failed protobuf generation!";
system($autogen_thrift) == 0 or die "Failed thrift generation!";