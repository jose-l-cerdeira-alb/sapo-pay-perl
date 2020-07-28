package SAPO::Broker::Transport::TCP_Async;

use AnyEvent::Handle;
use Carp qw(croak);

use strict;
use warnings;
use Data::Dumper;
use Time::HiRes "time";
use Errno;

use base qw(SAPO::Broker::Transport);

use constant DEBUG => 0;

sub new {
    my $class  = shift @_;
    my %params = @_;

    my $self = $class->SUPER::new(%params);

		$self->{_error_cb} = $params{error_cb} if $params{error_cb};
		
    #print STDERR __PACKAGE__ . "::params: ", Dumper( \%params );
    my $socket = AnyEvent::Handle->new(
        connect => [ $params{host}, $params{port} ],

        #on_rtimeout => sub { die "read timeout" },
        #on_wtimeout => sub { die "write timeout" },
        #on_eof => sub { delete $self->{__socket} },
				on_eof => sub {
          delete $self->{__socket};
          #print STDERR "on_eof\n";
					$params{eof_cb}->() if $params{eof_cb};
				},

        on_error => sub {
            my ( $h, $fatal, $msg ) = @_;

            #print STDERR "on_error: [$fatal]\n";
            $self->__drain($fatal,$msg);
            $self->{_error_cb}->($fatal,$msg) if exists $self->{_error_cb};

            delete $self->{__socket} if $fatal;
        },
        on_prepare => sub {

            #print STDERR "on prepare\n";
            return $params{ctimeout} || 10;
        },

				on_connect => sub { $params{connect_cb}->() if $params{connect_cb} },
        #on_connect => sub { shift->timeout_reset },
        #autocork  => 1,
				no_delay => 1,
        keepalive => 1,
    );

    if ( defined $socket ) {
        $self->{__socket} = $socket;
        $self->{_wcbs}    = [];

        if ( defined $params{rcb} ) {
            $socket->on_read(
                sub {

                    #print STDERR "on_read\n";
                    $self->receive( cb => $params{rcb} );
                } );
        }

        if ( defined $params{wcb} ) {
            $socket->on_drain(
                sub {
                    $_[0]->wtimeout(0);
                    if ( !$self->__drain() ) {
                        $params{wcb}->();
                    }
                } );
        } else {
            $socket->on_drain( sub { $_[0]->wtimeout(0); $self->__drain } );
        }

        if ( $params{tls}) {
            $socket->starttls('connect');
        }

        return bless $self, $class;
    } else {
        die "Couldn't create socket. $!\n";
    }
} ## end sub new


sub __drain {
    my $self = shift;

    #print STDERR "on_drain\n";

    #$self->{__socket}->wtimeout(0);
    $self->{__socket}->wtimeout(0);

    if ( scalar @{ $self->{_wcbs} } ) {
        for my $cb ( @{ $self->{_wcbs} } ) {

            #print STDERR "on_drain: calling cb\n";
            $cb->(@_);
        }

        $self->{_wcbs} = [];
        return 1;
    }
}


sub __write {
    my ( $self, $payload, %args ) = @_;

    #print STDERR "__write", Dumper(\%args),"\n";

    if ( !exists $self->{__socket} ) { die "stale socket" }

    if ( defined $args{timeout} && $args{timeout} > 0 ) {
        $self->{__socket}->wtimeout( $args{timeout} );
    }

    $self->{__socket}->push_write($payload);
		#print STDERR "__write: after push ",length($payload)," bytes\n";

    if ( defined $args{cb} ) {
        push @{ $self->{_wcbs} }, $args{cb};
    }
}


sub __read {
	my ($self, $len, %args) = @_;
	
	if (!exists $self->{__socket}) { die "stale socket" }
	
	my $k = time();
	
	if (defined $args{timeout} && $args{timeout} > 0) {
		#$self->{__socket}->rtimeout( $args{timeout} );
		$self->{_t}{$k} = AnyEvent->timer(
			after => $args{timeout},
			cb => sub {
				if ($self->{_error_cb}) {
					$! = Errno::ETIMEDOUT;
					$self->{_error_cb}->(0,$!,"$!");
				}
			}
		);
	}
	
	print STDERR __PACKAGE__."::__read($len)\n" if DEBUG;
	$self->{__socket}->push_read(
		chunk => $len,
		sub {
			my (undef, $data) = @_;
			#$self->{__socket}->rtimeout(0);
			delete $self->{_t}{$k};
			print STDERR __PACKAGE__."::__read calling cb [$args{cb}]\n" if DEBUG;
			$args{cb}->($data) if exists $args{cb};
		} 
	);
}


sub _receive {
	my ($self) = @_;
	
	my $args = $self->{_rq}->[0];
	return unless $args;
	
	$self->__read(
		8,
		timeout => $args->{timeout},
		cb => sub {
			print STDERR __PACKAGE__."::read CB begin\n" if DEBUG;
			
			my ($type, $version, $length) = 
				SAPO::Broker::Transport::Message::__meta_from_header($_[0]);
			
			print STDERR __PACKAGE__."::read CB [$type][$version][$length]\n" if DEBUG;
			$self->__read(
				$length,
				timeout => $args->{timeout},
				cb => sub {
					my $msg = SAPO::Broker::Transport::Message->new({
						'type'    => $type,
						'version' => $version,
						'payload' => $_[0] 
					});
				
					print STDERR __PACKAGE__."::read CB 2 msg [",ref $msg,"]\n" if DEBUG;

					$args->{cb}->($msg) if exists $args->{cb};
					
					shift @{$self->{_rq}};
					$self->_receive();
				}
			);
		}
	);
}


sub send {
	my ( $self, $message, %args ) = @_;
	return $self->__write( $message->serialize(), %args );
}


sub receive {
	my ($self, %args) = @_;
	
	push @{$self->{_rq}}, { %args };
	return if scalar @{$self->{_rq}} > 1;
		
	$self->_receive()
}


sub destroy {
	my $self = shift;
	$self->{'__socket'}->destroy() if $self->{__socket};
}

=cut
sub DESTROY {
		my $self = shift;
		print STDERR __PACKAGE__ ."::DESTROY\n";
		$self->{'__socket'}->destroy() if $self->{__socket};
    #my $socket = $self->{'__socket'};
    #return $socket ? $socket->push_shutdown() : undef;
}
=cut

1;
