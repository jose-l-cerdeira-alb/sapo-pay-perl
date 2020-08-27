package SAPO::Broker::Messages::Message;

use SAPO::Broker::Utils qw(class);
use Readonly;

use strict;
use warnings;

Readonly::Array my @mandatory => qw(payload);
Readonly::Array my @optional  => qw(id timestamp expiration);

class(
    'mandatory' => \@mandatory,
    'optional'  => \@optional,
    'noheader'  => 1,
);

1;
