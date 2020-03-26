package SAPO::Broker::Messages::Accepted;

use SAPO::Broker::Utils qw(class);
use Readonly;

use strict;
use warnings;

Readonly::Array my @mandatory => qw(action_id);
Readonly::Array my @optional  => qw();

class(
    'mandatory' => \@mandatory,
    'optional'  => \@optional,
);

1;
