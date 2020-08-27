package SAPO::Broker::Messages::Poll;

use SAPO::Broker::Utils qw(class);
use Readonly;

use strict;
use warnings;

Readonly::Array my @mandatory => qw(destination timeout);
Readonly::Array my @optional  => qw(action_id);

class(
    'mandatory' => \@mandatory,
    'optional'  => \@optional,
);

1;
