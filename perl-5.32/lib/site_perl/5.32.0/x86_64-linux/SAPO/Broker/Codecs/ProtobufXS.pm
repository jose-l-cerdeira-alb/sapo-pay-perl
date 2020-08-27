package SAPO::Broker::Codecs::ProtobufXS;

use SAPO::Broker::Codecs::Autogen::ProtobufXS::Atom;
use SAPO::Broker::Messages;
use SAPO::Broker::Transport;
use Readonly;
use Carp qw(carp croak);

use strict;
use warnings;

Readonly::Scalar my $ENCODING_TYPE => 1;    #Protobuf encoding type

Readonly::Hash my %_string2kind => (
    'TOPIC'         => SAPO::Broker::Codecs::Autogen::ProtobufXS::Atom::DestinationType::TOPIC(),
    'QUEUE'         => SAPO::Broker::Codecs::Autogen::ProtobufXS::Atom::DestinationType::QUEUE(),
    'VIRTUAL_QUEUE' => SAPO::Broker::Codecs::Autogen::ProtobufXS::Atom::DestinationType::VIRTUAL_QUEUE(),
);

Readonly::Hash my %_kind2string => reverse(%_string2kind);

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub name {
    return 'Protobuf';
}

sub _string2kind($) {
    my ($kind) = @_;

    my $res = $_string2kind{$kind};
    if ( defined $res ) {
        return $res;
    } else {
        croak("Unknown kind $kind");
    }
}

sub _kind2string($) {
    my ($kind) = @_;

    my $res = $_kind2string{$kind};
    if ( defined $res ) {
        return $res;
    } else {
        croak("Unknown kind $kind");
        return;
    }
}

sub serialize_publish($) {
    my ($message) = @_;

    local $message->{'destination_type'} = _string2kind( $message->{'destination_type'} );
    my $broker_message = $message->message();

    my $ret = SAPO::Broker::Codecs::Autogen::ProtobufXS::Atom->new( {
            'action' => {
                'publish'     => $message,
                'action_type' => SAPO::Broker::Codecs::Autogen::ProtobufXS::Atom::Action::ActionType::PUBLISH()
            },
        } );

    #broker expects milliseconds
    my $expiration = $broker_message->expiration();
    if ( defined $expiration ) {
        $ret->action->publish->message->set_timestamp( $expiration * 1000 );
    }

    my $timestamp = $broker_message->timestamp();
    if ( defined $timestamp ) {
        $ret->action->publish->message->set_timestamp( $timestamp * 1000 );
    }

    return $ret;
} ## end sub serialize_publish($)

sub serialize_poll($) {
    my ($message) = @_;

    return SAPO::Broker::Codecs::Autogen::ProtobufXS::Atom->new( {
            'action' => {
                'poll'        => $message,
                'action_type' => SAPO::Broker::Codecs::Autogen::ProtobufXS::Atom::Action::ActionType::POLL()
            },
        } );
}

sub parse_accepted($) {
    my ($action) = @_;

    return SAPO::Broker::Messages::Accepted->new( $action->accepted()->to_hashref );
}

sub serialize_acknowledge($) {
    my ($message) = @_;

    return SAPO::Broker::Codecs::Autogen::ProtobufXS::Atom->new( {
            'action' => {
                'ack_message' => $message,

                'action_type' =>
                    SAPO::Broker::Codecs::Autogen::ProtobufXS::Atom::Action::ActionType::ACKNOWLEDGE_MESSAGE(),

            } } );
}

sub serialize_subscribe($) {
    my ($message) = @_;

    local $message->{'destination_type'} = _string2kind( $message->{'destination_type'} );

    return SAPO::Broker::Codecs::Autogen::ProtobufXS::Atom->new( {
            'action' => {
                'subscribe'   => $message,
                'action_type' => SAPO::Broker::Codecs::Autogen::ProtobufXS::Atom::Action::ActionType::SUBSCRIBE()
            },
        } );
}

sub serialize_unsubscribe($) {
    my ($message) = @_;

    local $message->{'destination_type'} = _string2kind( $message->{'destination_type'} );

    return SAPO::Broker::Codecs::Autogen::ProtobufXS::Atom->new( {
            'action' => {
                'unsubscribe' => $message,
                'action_type' => SAPO::Broker::Codecs::Autogen::ProtobufXS::Atom::Action::ActionType::UNSUBSCRIBE()
            },
        } );
}

sub parse_notification($) {
    my ($action) = @_;

    my $notification = SAPO::Broker::Messages::Notification->new( $action->notification()->to_hashref() );
    my $message      = $notification->{'message'};
    $message->{'id'}                    = $message->{'message_id'};
    $notification->{'destination_type'} = _kind2string( $notification->{'destination_type'} );
    $notification->{'message'}          = SAPO::Broker::Messages::Message->new($message);

    #take care of the milliseconds

    for my $field (qw(expiration timestamp)) {
        my $val = $message->{$field};
        if ( defined $val ) {
            $message->{$field} = $val / 1000.;
        }
    }

    #now cast the actual message containing the payload
    $notification->message( SAPO::Broker::Messages::Message->new($message) );
    return $notification;
} ## end sub parse_notification($)

sub parse_fault($) {
    my ($action) = @_;

    return SAPO::Broker::Messages::Fault->new( $action->fault()->to_hashref );
}

sub serialize_ping($) {
    my ($message) = @_;

    return SAPO::Broker::Codecs::Autogen::ProtobufXS::Atom->new( {
            'action' => {
                'ping'        => $message,
                'action_type' => SAPO::Broker::Codecs::Autogen::ProtobufXS::Atom::Action::ActionType::PING()
            },
        } );
}

sub parse_pong($) {
    my ($action) = @_;

    return SAPO::Broker::Messages::Pong->new( $action->pong()->to_hashref );
}

sub serialize_authentication($) {
    my ($message) = @_;

    return SAPO::Broker::Codecs::Autogen::ProtobufXS::Atom->new( {
            'action' => {
                'auth'        => $message,
                'action_type' => SAPO::Broker::Codecs::Autogen::ProtobufXS::Atom::Action::ActionType::AUTH()
            },
        } );
}

my %__dispatch_serialize = (
    'SAPO::Broker::Messages::Publish'        => \&serialize_publish,
    'SAPO::Broker::Messages::Poll'           => \&serialize_poll,
    'SAPO::Broker::Messages::Acknowledge'    => \&serialize_acknowledge,
    'SAPO::Broker::Messages::Subscribe'      => \&serialize_subscribe,
    'SAPO::Broker::Messages::Unsubscribe'    => \&serialize_unsubscribe,
    'SAPO::Broker::Messages::Ping'           => \&serialize_ping,
    'SAPO::Broker::Messages::Authentication' => \&serialize_authentication,
);

my %__dispatch_deserialize = (
    SAPO::Broker::Codecs::Autogen::ProtobufXS::Atom::Action::ActionType::NOTIFICATION() => \&parse_notification,
    SAPO::Broker::Codecs::Autogen::ProtobufXS::Atom::Action::ActionType::FAULT()        => \&parse_fault,
    SAPO::Broker::Codecs::Autogen::ProtobufXS::Atom::Action::ActionType::PONG()         => \&parse_pong,
    SAPO::Broker::Codecs::Autogen::ProtobufXS::Atom::Action::ActionType::ACCEPTED()     => \&parse_accepted,
);

sub serialize {
    my ( $self, $message ) = @_;

    #try to find the serializer
    #could use ref but I wan't to make this robust to serialize subclasses of broker messages
    #since there are few classes, iterating should not be much slower that using the hash table

    while ( my ( $class, $serializer ) = each(%__dispatch_serialize) ) {
        if ( $message->isa($class) ) {

            #reset the hash iterator
            scalar keys(%__dispatch_serialize);

            my $atom   = $serializer->($message);
            my $header = $message->{'header'};
            if ( 'HASH' eq ref($header) ) {
                my $header_obj = SAPO::Broker::Codecs::Autogen::ProtobufXS::Atom::Header->new();
                while ( my ( $name, $value ) = each(%$header) ) {
                    $header_obj->add_parameter(
                        SAPO::Broker::Codecs::Autogen::ProtobufXS::Atom::Parameter->new( {
                                'name'  => $name,
                                'value' => $value
                            },
                        ) );
                }
                $atom->set_header($header_obj);
            }
            my $payload = $atom->pack();

            return SAPO::Broker::Transport::Message->new(
                type    => $ENCODING_TYPE,
                version => 1,
                payload => $payload
            );
        } ## end if ( $message->isa($class...))
    } ## end while ( my ( $class, $serializer...))

    croak("Can't serialize $message");
    return;
} ## end sub serialize

sub __deserialize {
    my ( $self, $payload ) = @_;

    return SAPO::Broker::Codecs::Autogen::ProtobufXS::Atom->new($payload);
}

sub deserialize {
    my ( $self, $payload ) = @_;

    my $atom = $self->__deserialize($payload);
    my $header = $atom->header->to_hashref() // {};
    $header = $header->{'parameter'};
    my $action = $atom->action();

    my $deserialize = $__dispatch_deserialize{ $action->action_type() };
    if ($deserialize) {
        my $msg = $deserialize->($action);

        if ( 'ARRAY' eq ref($header) ) {
            my %header = map { $_->{'name'}, $_->{'value'} } @$header;
            $msg->{'header'} = \%header;
        }

        return $msg;

    } else {
        croak( "Unknown action_type " . $action->action_type() . ". Can't deserialize" );
        return;
    }
} ## end sub deserialize

1;
