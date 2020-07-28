package SAPO::Broker::Messages::Fault;

use SAPO::Broker::Utils qw(class);
use Readonly;

use strict;
use warnings;

Readonly::Array my @mandatory => qw(fault_code fault_message);
Readonly::Array my @optional  => qw(fault_detail action_id);

class(
    'mandatory' => \@mandatory,
    'optional'  => \@optional,
);

1;
