package SAPO::Broker::Clients::Minimal;

use Carp qw(carp croak);

our @PARAMETERS = (qw(codec transport));

use strict;
use warnings;

sub new {
    my ( $pack, %options ) = @_;

    my $self = bless {}, $pack;

    for my $field (@PARAMETERS) {
        my $value = $options{$field};

        if ( defined($field) ) {
            $self->{$field} = $value;
        } else {
            croak("Missing mandatory parameter $field");
        }
    }

    return $self;
}

sub send {
    my ( $self, $message ) = @_;
    my $data = $self->{'codec'}->serialize($message);
    $self->{'transport'}->send($data);
    return $self;
}

sub receive {
    my ($self) = @_;
    my $net_msg = $self->{'transport'}->receive();

    #for now ignore the type and version fields
    #TODO use type and version to choose the best codec
    return $self->{'codec'}->deserialize( $net_msg->payload );
}

1;
