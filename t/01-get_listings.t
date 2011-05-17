#!perl

use strict; use warnings;
use TV::ProgrammesSchedules::SAB;
use Test::More tests => 1;

my $sab = TV::ProgrammesSchedules::SAB->new();

eval { $sab->get_listings('abc'); };
like($@, qr/Parameter #1 \("abc"\) to TV::ProgrammesSchedules::SAB::get_listings did not pass/);