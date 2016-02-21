package Toolkit;

use strict;
use base qw( Exporter );
no warnings qw( redefine );

use PSInfo;
use StructurePrinter;
use Utilities qw( :ALL );
use Profiler;
use Progress;

our $VERSION = 0.1;

our @EXPORT;

sub import {
  my %supported = (
    Profiler         => [@Profiler::EXPORT],
    StructurePrinter => [@StructurePrinter::EXPORT],
    Utilities        => [@Utilities::EXPORT_OK],
  );

  my %seen;
  foreach my $package (keys %supported) {
    foreach my $name (@{$supported{$package}}) {
      if(!exists($seen{$name})) {
        no strict 'refs';
        push(@Toolkit::EXPORT, $name);
        *{"Toolkit::$name"} = sub { &{"Utilities::$name"}(@_); };
        $seen{$name} = undef;
      } else {
        warn("Toolkit already has a [$name]. Will not reassing\n");
      }
    }
  }
  Toolkit->export_to_level(1, @_);
}

1;
