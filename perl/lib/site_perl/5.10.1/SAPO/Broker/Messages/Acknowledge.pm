package SAPO::Broker::Messages::Acknowledge;

use SAPO::Broker::Utils qw(class);
use Readonly;

use strict;
use warnings;

Readonly::Array my @mandatory => qw(message_id destination);
Readonly::Array my @optional  => qw(action_id);

class(
    'mandatory' => \@mandatory,
    'optional'  => \@optional,
);

1;
