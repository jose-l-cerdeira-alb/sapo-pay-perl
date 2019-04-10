# ====
#  SSL/STARTTLS extention for Graham Barr's Net::POP3.
#    plus, enable arbitrary POP auth mechanism selection.
#      IO::Socket::SSL (also Net::SSLeay openssl),
#      Authen::SASL, MIME::Base64 should be installed.
#
package Net::POP3S;

use vars qw ( $VERSION @ISA );

$VERSION = "0.04";

use base qw ( Net::POP3 );
use Net::Cmd;  # import CMD_OK, CMD_MORE, ...
use Net::Config;

eval {
    require IO::Socket::INET6
	and unshift @ISA, 'IO::Socket::INET6';
} or do {
    require IO::Socket::INET
	and unshift @ISA, 'IO::Socket::INET';
};

use strict;

# Override to support SSL/TLS.
sub new {
  my $self = shift;
  my $type = ref($self) || $self;
  my ($host, %arg);
  if (@_ % 2) {
      $host = shift;
      %arg  = @_;
  }
  else {
      %arg  = @_;
      $host = delete $arg{Host};
  }
  my $ssl = delete $arg{doSSL};

  my $hosts = defined $host ? $host : $NetConfig{pop3_hosts};
  my $obj;
  my @localport = exists $arg{ResvPort} ? (LocalPort => $arg{ResvPort}) : ();

  # eliminate IO::Socket::SSL from @ISA for multiple call of new.
  @ISA = grep { !/IO::Socket::SSL/ } @ISA;

  my $h;
  foreach $h (@{ref($hosts) ? $hosts : [$hosts]}) {
    $obj = $type->SUPER::new(
      PeerAddr => ($host = $h),
      PeerPort => $arg{Port} || 'pop3(110)',
      Proto     => 'tcp',
      @localport,
      Timeout   => defined $arg{Timeout}
      ? $arg{Timeout}
      : 120
      )
      and last;
  }

  return undef
    unless defined $obj;

  ${*$obj}{'net_pop3_host'} = $host;

  $obj->autoflush(1);
  $obj->debug(exists $arg{Debug} ? $arg{Debug} : undef);

# common in SSL
  my %ssl_args;
  if ($ssl) {
    eval {
      require IO::Socket::SSL;
    } or do {
      $obj->set_status(500, ["Need working IO::Socket::SSL"]);
      $obj->close;
      return undef;
    };
    %ssl_args = map { +"$_" => $arg{$_} } grep {/^SSL/} keys %arg;
    $IO::Socket::SSL::DEBUG = (exists $arg{Debug} ? $arg{Debug} : undef); 
  }

# OverSSL
  if (defined($ssl) && $ssl =~ /ssl/i) {
    $obj->ssl_start(\%ssl_args)
      or do {
	 $obj->set_status(500, ["Cannot start SSL"]);
	 $obj->close;
	 return undef;
      };
  }

  unless ($obj->response() == CMD_OK) {
    $obj->close();
    return undef;
  }

  ${*$obj}{'net_pop3_banner'} = $obj->message;

# STARTTLS
  if (defined($ssl) && $ssl =~ /starttls|stls/i ) {
     my $capa;
    ($capa = $obj->capa
     and exists $capa->{STLS}
     and ($obj->command('STLS')->response() == CMD_OK)
     and $obj->ssl_start(\%ssl_args))
       or do {
	 $obj->set_status(500, ["Cannot start SSL session"]);
	 $obj->close();
	 return undef;
       };
  }

  $obj;
}

sub ssl_start {
    my ($self, $args) = @_;
    my $type = ref($self);

    (unshift @ISA, 'IO::Socket::SSL'
     and IO::Socket::SSL->start_SSL($self, %$args)
     and $self->isa('IO::Socket::SSL')
     and bless $self, $type     # re-bless 'cause IO::Socket::SSL blesses himself.
    ) or return undef;
}

# Override to specify a certain auth mechanism.
sub auth {
  my ($self, $username, $password, $mechs) = @_;

  eval {
    require MIME::Base64;
    require Authen::SASL;
  } or $self->set_status(500, ["Need MIME::Base64 and Authen::SASL todo auth"]), return 0;

  my $mechanisms = undef;
  if ($mechs) {
      $mechanisms = $mechs;
  } else {
    my $capa    = $self->capa;
    $mechanisms = $capa->{SASL} || 'CRAM-MD5';
  }

  my $sasl;

  if (ref($username) and UNIVERSAL::isa($username, 'Authen::SASL')) {
    $sasl = $username;
    my $user_mech = $sasl->mechanism || '';
    my @user_mech = split(/\s+/, $user_mech);
    my %user_mech;
    @user_mech{@user_mech} = ();

    my @server_mech = split(/\s+/, $mechanisms);
    my @mech = @user_mech
      ? grep { exists $user_mech{$_} } @server_mech
      : @server_mech;
    unless (@mech) {
      $self->set_status(
        500,
        [ 'Client SASL mechanisms (',
          join(', ', @user_mech),
          ') do not match the SASL mechnism the server announces (',
          join(', ', @server_mech), ')',
        ]
      );
      return 0;
    }

    $sasl->mechanism(join(" ", @mech));

    $sasl->mechanism($mechanisms);
  }
  else {
    die "auth(username, password)" if not length $username;
    $sasl = Authen::SASL->new(
      mechanism => $mechanisms,
      callback  => {
        user     => $username,
        pass     => $password,
        authname => $username,
      }
    );
  }

  # We should probably allow the user to pass the host, but I don't
  # currently know and SASL mechanisms that are used by smtp that need it
  my ($hostname) = split /:/, ${*$self}{'net_pop3_host'}; # /
  my $client = eval { $sasl->client_new('pop', $hostname, 0) };

  unless ($client) {
    my $mech = $sasl->mechanism;
    $self->set_status(
      500,
      [ " Authen::SASL failure: $@",
        '(please check if your local Authen::SASL installation',
        "supports mechanism '$mech'"
      ]
    );
    return 0;
  }

  my ($token) = $client->client_start
    or do {
    my $mech = $client->mechanism;
    $self->set_status(
      500,
      [ ' Authen::SASL failure:  $client->client_start ',
        "mechanism '$mech' hostname #$hostname#",
        $client->error
      ]
    );
    return 0;
    };

  # We dont support sasl mechanisms that encrypt the socket traffic.
  # todo that we would really need to change the ISA hierarchy
  # so we dont inherit from IO::Socket, but instead hold it in an attribute

  my @cmd = ("AUTH", $client->mechanism);
  my $code;

  push @cmd, MIME::Base64::encode_base64($token, '')
    if defined $token and length $token;

  while (($code = $self->command(@cmd)->response()) == CMD_MORE) {

    my ($token) = $client->client_step(MIME::Base64::decode_base64(($self->message)[0])) or do {
      $self->set_status(
        500,
        [ ' Authen::SASL failure:  $client->client_step ',
          "mechanism '", $client->mechanism, " hostname #$hostname#, ",
          $client->error
        ]
      );
      return 0;
    };

    @cmd = (MIME::Base64::encode_base64(defined $token ? $token : '', ''));
  }

  $code == CMD_OK;

}

1;

__END__

=head1 NAME

Net::POP3S - SSL/STARTTLS support for Net::POP3

=head1 SYNOPSYS

    use Net::POP3S;

    my $ssl = 'ssl';   # 'ssl' / 'starttls'|'stls' / undef

    my $pop3 = Net::POP3S->new("pop.example.com", Port => 995, doSSL => $ssl);

=head1 DESCRIPTION

This module implements a wrapper for Net::POP3, enabling over-SSL/STARTTLS support.
This module inherits all the methods from Net::POP3. You may use all the friendly
options that came bundled with Net::POP3.
You can control the SSL usage with the options of new() constructor method.
'doSSL' option is the switch, and, If you would like to control detailed SSL settings,
you can set SSL_* options that are brought from IO::Socket::SSL. Please see the
document of IO::Socket::SSL about these options detail.

Just one method difference from the Net::POP3, you may select POP AUTH mechanism
as the third option of auth() method.

=head1 METHODS

Most of all methods of Net::POP3 are inherited as is, except auth().


=over 4

=item auth ( USERNAME, PASSWORD [, AUTHMETHOD])

Attempt SASL authentication through Authen::SASL module. AUTHMETHOD is your required
method of authentication, like 'CRAM-MD5', 'LOGIN', ... etc. the default is 'CRAM-MD5'.

=back

=head1 SEE ALSO

L<Net::POP3>,
L<IO::Socket::SSL>,
L<Authen::SASL>

=head1 AUTHOR

Tomo.M E<lt>tomo at cpan orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Tomo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
