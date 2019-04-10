#!/usr/bin/env perl

use strict;

use FindBin qw($Bin);
use File::Spec::Functions qw(catfile);

my $proto_file = catfile($Bin, '..','..', 'binding', 'thrift', 'src', 'main', 'thrift', 'broker.thrift');

system('thrift', '-v', '-debug', '--gen', 'perl', '-o', $Bin, $proto_file);
if(0==$?){
    my $gen_perl = catfile($Bin, 'gen-perl');
    system('cp', '-av',glob(catfile($gen_perl, '*')), catfile($Bin, 'lib'));
    system('rm', '-rf', $gen_perl);
}