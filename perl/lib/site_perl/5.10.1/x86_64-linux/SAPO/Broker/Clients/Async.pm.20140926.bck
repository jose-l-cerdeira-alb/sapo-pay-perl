package SAPO::Broker::Clients::Async;

use Carp qw(carp croak);

use SAPO::Broker::Utils qw(has_ssl has_thrift has_protobufxs has_thriftxs);
use SAPO::Broker::Messages;
use SAPO::Broker::Transport::TCP_Async;

use strict;
use warnings;

=head
#don't fail if SSL is not a viable transport (please install IO::Socket::SSL)

my $has_ssl = has_ssl();
if ($has_ssl) {
    eval 'use SAPO::Broker::Transport::SSL';
}
=cut

my %DEFAULT_OPTIONS = ();    # 'proto' => 'tcp_async' );

#our @ISA = qw(SAPO::Broker::Clients::Minimal);
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

    my $self;
    my ( $rcb, $wcb );

    if ( defined $options{rcb} ) {
        $rcb = sub {
            $self->receive(
                timeout => $options{rtimeout},
                cb      => $options{rcb} );
        };
    }

=head
		if (defined $options{wcb}) {
			$wcb = sub {
				$self->xxxx(timeout => $options{wtimeout}, cb => $options{wcb})
			};
    }
=cut

    $self = bless {
        codec     => __get_codec(%options),
        transport => SAPO::Broker::Transport::TCP_Async->new(
            %options,
            rcb => $rcb,
            wcb => $wcb
        ),

        #__get_transport_class(%options)->new(%options, rcb => $rcb),
    }, $pack;

    $self->{'auto_ack'} = {};

    if ( defined $options{rcb} ) {
        $self->{rcb} = sub {
            $self->receive(
                timeout => $options{rtimeout},
                cb      => $options{rcb} );
        };
    }

    return $self;
} ## end sub new


sub destroy {
	my $self = shift;
	#print STDERR __PACKAGE__."::DESTROY\n";
	$self->{transport}->destroy if $self->{transport}
}


sub __get_codec {
    my (%options) = @_;
    my $codec_name = lc( $options{'codec'} );

    if (    ref($codec_name)
        and $codec_name->can('serialize')
        and $codec_name->can('deserialize') ) {

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
} ## end sub __get_codec

=head
sub __get_transport_class {
    my (%options) = @_;

    my $proto  = lc( $options{'proto'} );
    my $prefix = 'SAPO::Broker::Transport::';

    if ($proto eq 'tcp') {
        return $prefix . 'TCP';
    } elsif ( $proto eq 'tcp_async' ) {
        return $prefix . 'TCP_Async';
    } elsif ( $proto eq 'udp' ) {
        return $prefix . 'UDP';
    } elsif ( $has_ssl and $proto eq 'ssl' ) {
        return $prefix . 'SSL';
    } else {
        croak("Unknown protocol '$proto'");
    }
}
=cut

sub __can_acknowledge {
    my ($kind) = @_;
    return $kind eq 'QUEUE' or $kind eq 'VIRTUAL_QUEUE';
}

sub subscribe {
    my ( $self, %options ) = @_;

    my $subscribe = SAPO::Broker::Messages::Subscribe->new(%options);
    my $ret = $self->send( $subscribe, %options );

    if ( __can_acknowledge( $options{'destination_type'} )
        and $options{'auto_acknowledge'} ) {

        #add the queue name to the auto_ack queue
        $self->{'auto_ack'}->{ $options{'destination'} } = '+inf';    #acknowledge all messages
    }
}

sub unsubscribe {
    my ( $self, %options ) = @_;

    my $unsubscribe = SAPO::Broker::Messages::Unsubscribe->new(%options);
    $self->send($unsubscribe);
}

sub poll {
    my ( $self, %options ) = @_;
    my $poll = SAPO::Broker::Messages::Poll->new(
        'timeout' => 0,
        %options
    );

    $self->send(
        $poll, %options,
        cb => sub {
            if ( $options{'auto_acknowledge'} ) {
                $self->{'auto_ack'}->{ $options{'destination'} } += 1;
            }

            $options{cb}->() if $options{cb};
        } );
}

sub acknowledge {
    my ( $self, $notification, %args ) = @_;

    my $id          = $notification->message->id;
    my $destination = $notification->destination;
    my $ack         = SAPO::Broker::Messages::Acknowledge->new(
        'message_id'  => $id,
        'destination' => $destination
    );
    return $self->send( $ack, %args );
}

sub publish {
    my ( $self, %options ) = @_;

    if ( exists( $options{'payload'} ) ) {
        my $message = SAPO::Broker::Messages::Message->new(%options);
        my $publish = SAPO::Broker::Messages::Publish->new( %options, 'message' => $message );

        $self->send( $publish, %options );
    } else {
        carp("no payload to publish");
    }
}

sub authenticate {
    my ( $self, $username, $password, %args ) = @_;

    if ( defined($username) and defined($password) ) {
        my $auth = SAPO::Broker::Messages::Authentication::from_sts_credentials(
            'username' => $username,
            'password' => $password
        );
        $self->send( $auth, %args );
    } else {
        croak "username and password mandatory";
    }
}

sub receive {
    my ( $self, %args ) = @_;

    #get the actual message from the base class
    #my $message = $self->SUPER::receive();
    $self->{'transport'}->receive(
        timeout => $args{timeout},
        cb      => sub {
            my ($data) = @_;

            #now check the message type
            #if it is a fault just raise an exception
            my $message = $self->{'codec'}->deserialize( $data->payload );

            #possible inheritance problems
            my $msg_type = ref($message);

            #print STDERR "Async::Receive: [$msg_type]\n";

            if ( $msg_type eq 'SAPO::Broker::Messages::Fault' ) {
                warn __PACKAGE__ . " " . $message->fault_message;
                die $message;

                #otherwise return the message with no modification
            } elsif ( $msg_type eq 'SAPO::Broker::Messages::Notification' ) {

                #try to find whether we need to acknowledge
                my $auto_ack_count = \$self->{'auto_ack'}->{ $message->destination };

                if (    __can_acknowledge( $message->destination_type )
                    and defined($$auto_ack_count)
                    and $$auto_ack_count > 0 ) {

                    $self->acknowledge($message);
                    --$$auto_ack_count;
                }
            }

            $args{cb}->($message) if $args{cb};
        } );
} ## end sub receive

## end sub receive

sub send {
    my ( $self, $message, %args ) = @_;
    my $data = $self->{'codec'}->serialize($message);
    $self->{'transport'}->send( $data, %args );
}

1;
