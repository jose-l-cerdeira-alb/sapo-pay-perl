package SAPO::Broker::Messages::Unsubscribe;

use SAPO::Broker::Utils qw(class);
use Readonly;

use strict;
use warnings;

Readonly::Array my @mandatory => qw(destination destination_type);
Readonly::Array my @optional  => qw(action_id);

class(
    'mandatory' => \@mandatory,
    'optional'  => \@optional,
);

1;
