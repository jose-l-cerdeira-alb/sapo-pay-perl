#!/usr/bin/perl -Ilib -Iblib/lib

use strict;
use Business::MaxMind::TelephoneVerification;

my $license_key = 'ENTER_LICENSE_KEY_HERE';

my $telephone = 'ENTER_TELEPHONE_NUMBER_HERE';

my $telv = Business::MaxMind::TelephoneVerification->new(
		isSecure => 1,
		debug => 0,
		timeout => 30);

$telv->input(
	verify_code => '5783', # optional
	phone => $telephone,
	l => $license_key);

$telv->query;
my $hash_ref = $telv->output;

use Data::Dumper;
print Dumper($hash_ref);
