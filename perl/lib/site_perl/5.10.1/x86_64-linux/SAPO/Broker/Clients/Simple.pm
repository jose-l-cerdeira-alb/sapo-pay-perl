package SAPO::Broker::Clients::Simple;

use Carp qw(carp croak);

use SAPO::Broker::Utils qw(has_ssl has_thrift has_protobufxs has_thriftxs);
use SAPO::Broker::Messages;
use SAPO::Broker::Clients::Minimal;
use SAPO::Broker::Transport::TCP;
use SAPO::Broker::Transport::UDP;

use strict;
use warnings;

#don't fail if SSL is not a viable transport (please install IO::Socket::SSL)

my $has_ssl = has_ssl();
if ($has_ssl) {
    eval 'use SAPO::Broker::Transport::SSL';
}

my %DEFAULT_OPTIONS = ( 'proto' => 'tcp' );
our @ISA = qw(SAPO::Broker::Clients::Minimal);
my %codecs;

if ( has_thrift() ) {
    require SAPO::Broker::Codecs::Thrift;
    my $name = 'thrift';
    $codecs{$name} = SAPO::Broker::Codecs::Thrift->new();
    $DEFAULT_OPTIONS{'codec'} = $name;
}

if ( has_thriftxs() ) {
    require SAPO::Broker::Codecs::ThriftXS;
    my $name = 'thriftxs';
    $codecs{$name} = SAPO::Broker::Codecs::ThriftXS->new();
    $DEFAULT_OPTIONS{'codec'} = $name;
}

if ( has_protobufxs() ) {
    require SAPO::Broker::Codecs::ProtobufXS;
    my $name = 'protobufxs';
    $codecs{$name} = SAPO::Broker::Codecs::ProtobufXS->new();
    $DEFAULT_OPTIONS{'codec'} = $name;
}

sub new {
    my ( $pack, %options ) = @_;

    %options = ( %DEFAULT_OPTIONS, %options );

    my $codec     = __get_codec(%options);
    my $transport = __get_transport_class(%options)->new(%options);

    my $self = $pack->SUPER::new(
        'codec'     => $codec,
        'transport' => $transport,
    );

    $self->{'auto_ack'} = {};

    return $self;

}

sub __get_codec {
    my (%options) = @_;
    my $codec_name = lc( $options{'codec'} );

    if ( ref($codec_name) and $codec_name->can('serialize') and $codec_name->can('deserialize') ) {

        #codec is an objext
        return $codec_name;
    } else {

        my $codec = $codecs{$codec_name};

        if ($codec) {
            return $codec;
        } else {
            die "Codec $codec_name not available.";
        }
    }
}

sub __get_transport_class {
    my (%options) = @_;

    my $proto  = lc( $options{'proto'} );
    my $prefix = 'SAPO::Broker::Transport::';

    if ( $proto eq 'tcp' ) {
        return $prefix . 'TCP';
    } elsif ( $proto eq 'udp' ) {
        return $prefix . 'UDP';
    } elsif ( $has_ssl and $proto eq 'ssl' ) {
        return $prefix . 'SSL';
    } else {
        croak("Unknown protocol '$proto'");
    }
}

sub __can_acknowledge($) {
    my ($kind) = @_;
    return $kind eq 'QUEUE' or $kind eq 'VIRTUAL_QUEUE';
}

sub subscribe {
    my ( $self, %options ) = @_;

    my $subscribe = SAPO::Broker::Messages::Subscribe->new(%options);
    my $ret       = $self->send($subscribe);

    if ( __can_acknowledge( $options{'destination_type'} ) and $options{'auto_acknowledge'} ) {

        #add the queue name to the auto_ack queue
        $self->{'auto_ack'}->{ $options{'destination'} } = '+inf';    #acknowledge all messages
    }

    return $ret;
}

sub unsubscribe {
    my ( $self, %options ) = @_;

    my $unsubscribe = SAPO::Broker::Messages::Unsubscribe->new(%options);
    return $self->send($unsubscribe);
}

sub poll {
    my ( $self, %options ) = @_;
    my $poll = SAPO::Broker::Messages::Poll->new(
        'timeout' => 0,
        %options
    );
    my $ret = $self->send($poll);

    if ( $options{'auto_acknowledge'} ) {
        $self->{'auto_ack'}->{ $options{'destination'} } += 1;
    }
    return $ret;
}

sub acknowledge {
    my ( $self, $notification ) = @_;

    my $id          = $notification->message->id;
    my $destination = $notification->destination;
    my $ack         = SAPO::Broker::Messages::Acknowledge->new(
        'message_id'  => $id,
        'destination' => $destination
    );
    return $self->send($ack);
}

sub publish {
    my ( $self, %options ) = @_;

    if ( exists( $options{'payload'} ) ) {
        my $message = SAPO::Broker::Messages::Message->new(%options);
        my $publish = SAPO::Broker::Messages::Publish->new( %options, 'message' => $message );
        return $self->send($publish);
    } else {
        carp("no payload to publish");
        return $self;
    }
}

sub authenticate {
    my ( $self, $username, $password ) = @_;

    if ( defined($username) and defined($password) ) {
        my $auth = SAPO::Broker::Messages::Authentication::from_sts_credentials(
            'username' => $username,
            'password' => $password
        );
        return $self->send($auth);
    } else {
        croak "username and password mandatory";
    }
}

sub ping {
    my ( $self, $action_id ) = @_;

    if ( not defined $action_id ) {
        $action_id = int( time() . "_" . int( rand(1000000) ) );
    }

    my $ping = SAPO::Broker::Messages::Ping->new( 'action_id' => $action_id );
    return $self->send($ping);
}

sub receive {
    my ($self) = @_;

    #get the actual message from the base class
    my $message = $self->SUPER::receive();

    #now check the message type
    #if it is a fault just raise an exception

    #possible inheritance problems
    my $msg_type = ref($message);

    if ( $msg_type eq 'SAPO::Broker::Messages::Fault' ) {
        warn __PACKAGE__ . " " . $message->fault_message;
        die $message;

        #otherwise return the message with no modification
    } elsif ( $msg_type eq 'SAPO::Broker::Messages::Notification' ) {

        #try to find whether we need to acknowledge
        my $auto_ack_count = \$self->{'auto_ack'}->{ $message->destination };
        if ( __can_acknowledge( $message->destination_type ) and defined($$auto_ack_count) and $$auto_ack_count > 0 ) {
            $self->acknowledge($message);
            --$$auto_ack_count;
        }
        return $message;
    } else {
        return $message;
    }

} ## end sub receive

1;
