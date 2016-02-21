#!/usr/bin/perl

use strict;
use Digest::MD5 qw( md5_hex );
use IO::Handle;
use Test::More;

plan tests => 5;

use StructurePrinter;

# Test Objects
our $scalar   = join('', 'a' .. 'z');
our @list     = 'a' .. 'z';
our %hash     = map { ord($_) => hex(ord($_)) } 'a' .. 'z';
our $refsub   = sub { print("[", join("][", @_), "]\n"); };
our $deeptest = {
  'first'  => [0 .. 10],
  'second' => {a => 1, b => 2, c => 3},
  'third'  => sub { print("hello\n"); },
  'fourth' => {
    'aaa' => [2 .. 5],
    'bbb' => {z => 26, y => 25},
  }
};

test_it(\$scalar,  '2ada2b8f36929ff66ff8b6ae1e0bb0e6', 'Scalar Test');
test_it(\@list,    'bc63c454aaf00b44b622d2740356f587', 'List Test');
test_it(\%hash,    'd2d3abcefeae5f3c1b8c64472256332b', 'Hash Test');
test_it($refsub,   '1007a4d04bbfb135046e7ca5cafa826d', 'Sub Test');
test_it($deeptest, '8c808adfe9f9f69a1366710c8e8978be', 'Deep Test');

sub test_it {
  my ($obj, $expected, $label) = @_;

  my $capture;
  open(my $handler, '>', \$capture)
    or die("Cannot create capture handler\n");

  $handler->printObject($obj);
  $handler->close();

  $capture =~ s/0x[0-9a-f]+//gio;

  is(md5_hex($capture), $expected, $label);
}
