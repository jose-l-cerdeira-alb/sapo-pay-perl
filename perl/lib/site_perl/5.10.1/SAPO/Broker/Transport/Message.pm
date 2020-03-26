package SAPO::Broker::Transport::Message;

use SAPO::Broker::Utils qw(class);

use strict;
use warnings;

#don't remove this EVER!
use bytes;

class( 'mandatory' => [qw(payload type version)] );

sub serialized_header {
    my ($self) = @_;

    return __header_from_meta( $self->{'type'}, $self->{'version'}, length( $self->{'payload'} ) );
}

sub serialize {
    my ($self) = @_;

    return $self->serialized_header() . $self->{'payload'};
}

#utility static method
sub __meta_from_header($) {
    my ($data) = @_;
    return unpack( 'nnN', $data );
}

sub __header_from_meta {

    #my ($type, $version, $length) = @_;
    return pack( 'nnN', @_ );
}

1;
