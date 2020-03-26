package Business::MaxMind::HTTPBase;

use 5.006; # we use the utf8 pragma now.
           # Older perl installations should use 1.50

use strict;

use vars qw($VERSION $API_VERSION);

use LWP::UserAgent;
use URI::Escape;

$VERSION = '1.54';
$API_VERSION = join('/','Perl',$VERSION);

# default minfraud servers
my @defaultservers = ( 'minfraud.maxmind.com', 'minfraud-us-east.maxmind.com', 'minfraud-us-west.maxmind.com' );

sub new {
  my $i = 0;
  my ($class) = shift;
  if ($class eq 'Business::MaxMind::HTTPBase') {
    die "Business::MaxMind::HTTPBase is an abstract class - use a subclass instead";
  }
  my $self = { @_ };
  bless $self, $class;
  for my $server (@defaultservers){
    $self->{servers}->[$i] = $server;
    $i++;
  }
  unless ($self->{wsIpaddrRefreshTimeout}) {
    $self->{wsIpaddrRefreshTimeout} = 18000;  # default of 5 hours timeout
  }
  $self->{wsIpaddrCacheFile} ||= '/tmp/maxmind.ws.cache';
  $self->{ua} = LWP::UserAgent->new( ssl_opts => { verify_hostname => 0 } );
  $self->_init;
  return $self;
}

sub getServers {
  return [ @{ $_[0]->{servers} || [] } ];
}

sub setServers {
  my ( $self, $serverarrayref ) = @_;
  $self->{servers} = [@$serverarrayref];
}

sub writeIpAddressToCache {
  my ($self, $filename, $ipstr) = @_;
  my $datetime = time();
  open my $fh, ">$filename" or return;
  print $fh $ipstr . "\n";
  print $fh $datetime . "\n";
}

sub readIpAddressFromCache {
  my ($self) = @_;
  my $ipstr;
  my $datetime;
  if (-s $self->{wsIpaddrCacheFile} ) {
    open my $fh, $self->{wsIpaddrCacheFile};
    $ipstr = <$fh>;
    chomp($ipstr);
    $datetime = <$fh>;
    chomp($datetime);
  }

  unless ($ipstr && (time() - $datetime <= $self->{wsIpaddrRefreshTimeout})) {
    # refresh cached IP addresses if no IP address in file, or if refresh timeout expired
    if (my $tryIpstr = $self->readIpAddressFromWeb($ipstr)) {
      $ipstr = $tryIpstr;
    } else {
      if ($self->{debug}) {
	print STDERR "Warning, unable to get ws_ipaddr from www.maxmind.com\n";
      }
    }
    # we write to cache whether or not we were able to get $tryIpStr, since
    # in case DNS goes down, we don't want to check app/ws_ipaddr over and over
    $self->writeIpAddressToCache($self->{wsIpaddrCacheFile}, $ipstr);
  }
  return $ipstr;
}

sub readIpAddressFromWeb {
  my ($self) = @_;
  my $request = HTTP::Request->new('GET', "http://www.maxmind.com/app/ws_ipaddr");
  if ($self->{"timeout"} > 0) {
    $self->{ua}->timeout($self->{"timeout"});  
  }

  my $response = $self->{ua}->request($request);
  if ($response->is_success) {
    my $content = $response->content;
    chomp($content);
    if ($content =~ m!^(?:\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3};)*\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$!) {
      # is comma separated string of IP addresses
      return $content;
    }
  }
}

sub query {
  my ($self) = @_;
  my $s = $self->{servers};
  my $ipstr;
  my $datetime;

  unless ($self->{useDNS}) {
    $ipstr = $self->readIpAddressFromCache;
  }
  if ($ipstr) {
    my @ipaddr = split(";",$ipstr);
    for my $ip (@ipaddr) {
      my $result = $self->querySingleServer($ip);
      return $result if $result;
    }
  }
  for my $server (@$s) {
    my $result = $self->querySingleServer($server);
    return $result if $result;
  }
  return 0;
}

sub input {
  my $self = shift;
  my %vars = @_;
  while (my ($k, $v) = each %vars) {
    unless (exists $self->{allowed_fields}->{$k}) {
      die "invalid input $k - perhaps misspelled field?";
    }
    $self->{queries}->{$k} = $self->filter_field($k, $v);
  }
}

# sub-class should override this if it needs to filter inputs
sub filter_field {
  my ($self, $name, $value) = @_;
  return $value;
}

sub output {
  my $self = shift;
  return $self->{output};
}

# if possible send the escaped string as latin1 for backward compatibility.
# That makes a difference for chars 128..255
# otherwise use utf8 encoding.
#
sub _mm_uri_escape {
  return uri_escape($_[0]) if $] < 5.007;
  return utf8::downgrade( my $t = $_[0], 1 ) ?   uri_escape($_[0]) :  uri_escape_utf8($_[0]) ;
}

sub querySingleServer {
  my ($self, $server) = @_;
  my $url = ($self->{isSecure} ? 'https' : 'http') . '://' . $server . '/' .
      $self->{url};
  my $check_field = $self->{check_field};
  my $queries = $self->{queries};
  my $query_string = join('&', map { "$_=" . _mm_uri_escape($queries->{$_}) } keys %$queries);
  $query_string .= "&clientAPI=$API_VERSION";
  if ($self->{"timeout"} > 0) {
    $self->{ua}->timeout($self->{"timeout"});
  }
  my $request = HTTP::Request->new('POST', $url);
  $request->content_type('application/x-www-form-urlencoded');
  $request->content($query_string);
  if ($self->{debug}) {
    print STDERR "sending HTTP::Request: " . $request->as_string;
  }
  my $response = $self->{ua}->request($request);
  if ($response->is_success) {
    my $content = $response->content;
    my @kvpair = split(';',$content);
    my %output;
    for my $kvp (@kvpair) {
      my ($key, $value) = split('=',$kvp,2);
      $output{$key} = $value;
    }
    unless (exists $output{$check_field}) {
      return 0;
    }
    $self->{output} = \%output;
    return 1;
  } else {
    if ($self->{debug}) {
      print STDERR "Error querying $server code: " . $response->code;
    }
    return 0;
  }
}

1;
__END__

=head1 NAME

Business::MaxMind::HTTPBase - Base class for accessing HTTP web services

=head1 ABSTRACT

This is an abstract base class for accessing MaxMind web services.
Currently there are three subclasses, for Credit Card Fraud Detection,
Telephone Verification and Location Verification.  This class can be
used for other HTTP based web services as well.

=head1 METHODS

=over 4

=item new

Class method that returns a new object that is a subclass of Business::MaxMind::HTTPBase.
Will die if you attempt to call this for the Business::MaxMind::HTTPBase class, instead
you should call it on one of its subclasses.

=item input

Sets input fields.  See subclass for details on fields that should be set.
Returns 1 on success, 0 on failure.

=item query

Sends out query to MaxMind server and waits for response.  If the primary
server fails to respond, it sends out a request to the secondary server.
Returns 1 on success, 0 on failure.

=item output

Returns the output returned by the MaxMind server as a hash reference.

=back

=head1 SEE ALSO

L<Business::MaxMind::CreditCardFraudDetection>

L<http://www.maxmind.com/app/ccv_overview>

=head1 AUTHOR

TJ Mather, E<lt>tjmather@maxmind.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by MaxMind LLC

All rights reserved.  This package is free software and is licensed under
the GPL.  For details, see the COPYING file.

=cut
