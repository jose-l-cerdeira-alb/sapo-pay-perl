# Copyrights 2003-2018 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution User-Identity.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package User::Identity::Collection::Users;
use vars '$VERSION';
$VERSION = '0.99';

use base 'User::Identity::Collection';

use strict;
use warnings;

use User::Identity;


sub new(@)
{   my $class = shift;
    $class->SUPER::new(systems => @_);
}

sub init($)
{   my ($self, $args) = @_;
    $args->{item_type} ||= 'User::Identity';

    $self->SUPER::init($args);

    $self;
}

sub type() { 'people' }

1;

