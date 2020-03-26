package SAPO::Broker::Codecs::ThriftXS;

use Thrift::XS::BinaryProtocol;
use Thrift::XS::MemoryBuffer;

use base qw(SAPO::Broker::Codecs::Thrift);

use strict;
use warnings;

sub __serialize {
    my ( $self, $atom ) = @_;
    my $transport = Thrift::XS::MemoryBuffer->new();
    my $protocol  = Thrift::XS::BinaryProtocol->new($transport);
    $atom->write($protocol);
    my $payload = $transport->readAll( $transport->available() );
}

sub __deserialize {
    my ( $self, $payload ) = @_;

    my $atom = SAPO::Broker::Codecs::Autogen::Thrift::Atom->new();

    my $transport = Thrift::XS::MemoryBuffer->new();
    $transport->write($payload);
    my $protocol = Thrift::XS::BinaryProtocol->new($transport);
    $atom->read($protocol);

    return $atom;
}
1;
