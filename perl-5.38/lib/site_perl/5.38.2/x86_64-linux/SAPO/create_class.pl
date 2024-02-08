#!/usr/bin/env perl

use strict;

my $name = ucfirst(<>);
chomp($name);
my $mandatory = <>;
chomp($mandatory);
my $optional = <>;
chomp($optional);

my $code = "package SAPO::Broker::Messages::$name;

use SAPO::Broker::Utils qw(class);
use Readonly;

use strict;
use warnings;

Readonly::Array my \@mandatory => qw($mandatory);
Readonly::Array my \@optional  => qw($optional);

class(
    'mandatory' => \\\@mandatory,
    'optional'  => \\\@optional,
);

1;
";

open my $file, '>:raw', "$name.pm";
print $file $code;

close $file;
