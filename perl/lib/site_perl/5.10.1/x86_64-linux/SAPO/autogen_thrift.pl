#!/usr/bin/env perl

use strict;

use FindBin qw($Bin);
use File::Spec::Functions qw(catfile);

my $proto_file = catfile($Bin, '..','..', 'bindings', 'thrift', 'broker.thrift');

system('thrift', '-v', '-debug', '-perl', '-o', $Bin, $proto_file);
if(0==$?){
    my $gen_perl = catfile($Bin, 'gen-perl');
    system('cp', '-av',glob(catfile($gen_perl, '*')), catfile($Bin, 'lib'));
    system('rm', '-rf', $gen_perl);
}
