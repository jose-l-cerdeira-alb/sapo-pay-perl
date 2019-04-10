package SAPO::Broker::Transport::TCP;

use Readonly;
use Socket ();

use strict;
use warnings;

Readonly::Scalar my $DEFAULT_PORT => 3323;
Readonly::Scalar my $DEFAULT_HOST => '10.18.62.34';

use base qw(SAPO::Broker::Transport::INET);

sub new {
    my $self = shift @_;

    $self = $self->SUPER::new(
        'host' => $DEFAULT_HOST,
        'port' => $DEFAULT_PORT,
        @_, 'proto' => 'tcp'
    );

    #try to turn on TCP Keep-Alive
    eval {
        $self->{'__socket'}->setsockopt( Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1 ) or die $!;

        #linux specific stuff
        #$self->{'__socket'}->setsockopt(Socket::SOL_TCP, Socket::TCP_KEEPIDLE, 1) or die $!;
        #$self->{'__socket'}->setsockopt(Socket::SOL_TCP, Socket::TCP_KEEPCNT, 5) or die $!;
        #$self->{'__socket'}->setsockopt(Socket::SOL_TCP, Socket::TCP_KEEPINTVL, 1) or die $!;
        1;
    } or do {
        warn "Error setting TCP keep-alive: $@";
    };

    return $self;
} ## end sub new

sub send {
    my ( $self, $message ) = @_;

    $self->__write( $message->serialized_header() );
    $self->__write( $message->payload() );

    return $self;
}

1;
