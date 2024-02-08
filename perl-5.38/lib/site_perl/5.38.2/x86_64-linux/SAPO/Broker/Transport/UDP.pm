package SAPO::Broker::Transport::UDP;

use Readonly;

use strict;
use warnings;

use base qw(SAPO::Broker::Transport::INET);

Readonly::Scalar my $DEFAULT_PORT => 3323;
Readonly::Scalar my $DEFAULT_HOST => 'localhost';

sub new {
    my $self = shift @_;

    return $self->SUPER::new(
        'host' => $DEFAULT_HOST,
        'port' => $DEFAULT_PORT,
        @_, 'proto' => 'udp'
    );
}

1;
