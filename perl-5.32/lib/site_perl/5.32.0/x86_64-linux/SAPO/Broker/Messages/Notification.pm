package SAPO::Broker::Messages::Notification;

use SAPO::Broker::Utils qw(class);
use Readonly;

use strict;
use warnings;

Readonly::Array my @mandatory => qw(destination destination_type subscription message);
Readonly::Array my @optional  => qw();

class(
    'mandatory' => \@mandatory,
    'optional'  => \@optional,
);

1;
