package SAPO::Broker::Messages::Authentication;

use SAPO::Broker::Utils qw(class);
use Readonly;
use Carp qw(croak);

#dynamic use of modules so that if not installed nothing breaks
#there is just a loss of functionality
eval {
    require JSON::Any;
    require LWP::UserAgent;
    JSON::Any::import();
    LWP::UserAgent::import();
};

use strict;
use warnings;

Readonly::Array my @mandatory => qw(token authentication_type);
Readonly::Array my @optional  => qw(user_id role action_id);

class(
    'mandatory' => \@mandatory,
    'optional'  => \@optional,
);

my $sts_url = 'https://services.sapo.pt/STS/GetToken?';

sub from_sts_credentials {
    my %params = @_;
    my $url    = $sts_url;

    for my $param (qw(username password)) {
        my $value = $params{$param};
        if ( defined $value ) {
            $value =~ s/(\W)/sprintf"%%%x", ord($1)/ge;    #standalone urlescape
            $url .= "&ESB\u$param=$value";
            delete $params{$param};
        } else {
            croak "$param mandatory";
        }
    }

    $url .= '&JSON=True';

    my $ua = LWP::UserAgent->new(
        'agent'             => 'SAPO::Broker perl client',
        'protocols_allowed' => ['https'],
    );

    my $res = $ua->get($url);

    if ( $res->is_success ) {

        my $json   = $res->content;
        my $struct = JSON::Any->new->decode($json);
        my $token  = $struct->{'ESBToken'};
        if ( $token and ref($token) eq 'HASH' ) {
            my $ns = $token->{'xmlns'};

            if ( $ns and $ns eq 'http://services.sapo.pt/definitions' ) {
                return __PACKAGE__->new(
                    'authentication_type' => 'SapoSTS',
                    %params, 'token' => $token->{'value'} );
            } else {
                die "JSON with invalid namespace $ns [$json]";
            }
        } else {
            die "Invalid STS JSON [$json]";
        }
    } else {
        croak $res->status_line;
    }

} ## end sub from_sts_credentials

1;
