#!/usr/bin/env perl

use strict;

use FindBin qw($Bin);
use File::Spec::Functions qw(catfile);
use File::Copy qw(copy);

my $proto_dir = catfile($Bin, '..', '..', 'binding', 'protobuf', 'src', 'main', 'protobuf');
my $orig_proto_file = catfile($proto_dir, 'broker.proto');
my $gendir = catfile($Bin, 'protobufxs');
my $pmdir = catfile($Bin, 'lib', 'SAPO', 'Broker', 'Codecs', 'Autogen', 'ProtobufXS') ;
my $proto_file = catfile($gendir, 'broker.proto');
mkdir ($gendir);
mkdir ($pmdir);

#print $orig_proto_file,"\n";
#exit

open my $ifile, '<', $orig_proto_file or die $!;
open my $ofile, '>', $proto_file or die $!;

while(my $line=<$ifile>){
    $line =~ s/^\s*package\s+sapo_broker;/package SAPO.Broker.Codecs.Autogen.ProtobufXS;/;
    print $ofile $line;
}

close($ifile);
close($ofile);

my @args = ('protoc', "--cpp_out=$gendir", "--proto_path=$gendir" , $proto_file);
system(@args) == 0 or die "system @args failed: $?";
=head
if(0==$?){
    my $gen_perl = catfile($Bin, 'protobufxs');
    system('cp', '-av',glob(catfile($gen_perl, 'Atom.pm')), $pmdir);
    system('cp', '-av',glob(catfile($gen_perl, 'Atom.pod')), $pmdir);
}
=cut

unlink($proto_file);

grep {copy($_, $pmdir) && unlink($_)} ('Atom.pm', 'Atom.pod');
