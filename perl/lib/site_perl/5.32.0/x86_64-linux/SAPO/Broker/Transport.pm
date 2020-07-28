package SAPO::Broker::Transport;

use SAPO::Broker::Transport::Message;
use SAPO::Broker::Utils qw(class);
use Carp qw(croak);

use strict;
use warnings;

sub new {
    my ($pack) = @_;
    return bless {}, $pack;
}

sub send {
    my ( $self, $message ) = @_;

    $self->__write( $message->serialize() );

    return $self;
}

sub receive {
    my ($self) = @_;

    #read the header
    my ( $type, $version, $length ) = SAPO::Broker::Transport::Message::__meta_from_header( $self->__read(8) );

    #read the payload
    my $payload = $self->__read($length);

    return SAPO::Broker::Transport::Message->new( {
            'type'    => $type,
            'version' => $version,
            'payload' => $payload
    } );
}

1;
