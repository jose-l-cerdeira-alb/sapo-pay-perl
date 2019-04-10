package SAPO::Broker::Utils;

use base qw{Exporter};
use Carp qw(croak carp);
use strict;
use warnings;

our @EXPORT_OK = qw{
    &class
    &has_ssl
    &has_sapo_sts
    &has_protobufxs
    &has_thrift
    &has_thriftxs
    };

sub has_module($) {
    my ($module) = @_;

    eval "use $module;";

    return not $@;
}

sub has_ssl() {
    return has_module('IO::Socket::SSL');
}

sub has_sapo_sts() {
    return has_module('LWP') and has_module('Crypt::SSLeay') and has_module('JSON::Any');
}

sub has_protobufxs() {
    return has_module('SAPO::Broker::Codecs::Autogen::ProtobufXS::Atom');
}

sub has_thrift() {
    return has_module('Thrift') and has_module('SAPO::Broker::Codecs::Autogen::Thrift::Types');
}

sub has_thriftxs() {
    return has_module('Thrift::XS') and has_module('SAPO::Broker::Codecs::Autogen::Thrift::Types');
}

my $caller_pkg;

sub parent_sub($&) {
    my ( $name, $sub ) = @_;
    no strict 'refs';    ## no critic(ProhibitNoStrict) no other way around this
    *{ $caller_pkg . '::' . $name } = $sub;
    return;
}

#create simple classes on the fly
##try to keep dependencies to a minimum
sub class {
    my (%params) = @_;

    #XXX non reentrant
    $caller_pkg = caller(0);

    my @mandatory = @{ $params{'mandatory'} || [] };
    my @optional  = @{ $params{'optional'}  || [] };
    my $has_header = not $params{'noheader'};

    #aux function to create functions in the caller namespace

    #try to get carp and croak to report actual package
    local $Carp::CarpLevel = $Carp::CarpLevel + 1;    ## no critic

    #generate the constructor

    parent_sub 'new', sub {
        my ( $class, @params ) = @_;

        my %params;
        my $first_param = $params[0];

        if ( @params and UNIVERSAL::isa( $first_param, 'HASH' ) ) {
            %params = %$first_param;
        } else {
            %params = @params;
        }

        my $self = {};

        #check mandatory parameters
        for my $param (@mandatory) {
            if ( exists( $params{$param} ) ) {
                $self->{$param} = $params{$param};
            } else {
                croak "Missing mandatory parameter $param";
            }
        }

        #copy optional parameters
        for my $param (@optional) {
            if ( exists( $params{$param} ) ) {
                $self->{$param} = $params{$param};
            }
        }

        if ($has_header) {
            my $header = $params{'header'};
            if ( 'HASH' eq ref($header) ) {
                $self->{'header'} = $header;
            }
        }

        return bless $self, $class;
    };

    #generate getters and setters
    for my $param ( @mandatory, @optional ) {
        parent_sub $param, sub {
            my ( $self, $value ) = @_;
            if ( @_ > 1 ) {
                $self->{$param} = $value;
                return $self;
            } else {
                return $self->{$param};
            }
        };
    }

    #header code
    if ($has_header) {
        parent_sub 'header', sub {
            my ($self) = @_;
            my $header = $self->{'header'};

            if ( not defined $header ) {
                $header = {};
                $self->{'header'} = $header;
            }

            return $header;
        };
    }

    return;
} ## end sub class

1;
