package StructurePrinter;

use strict;
use B::Deparse;
use IO::Handle;

use base qw( Exporter );
our @EXPORT = qw( printObject );

our $VERSION = 0.90;

our %dispatch = (
  ARRAY  => \&_printArray,
  CODE   => \&_printCode,
  HASH   => \&_printHash,
  SCALAR => \&_printScalar,
);

our $match = join( '|', keys(%dispatch) );

sub import {
  no strict 'refs';
  my $caller = ( caller() )[0];
  *{"$caller\::printObject"} = sub { STDOUT->printObject(@_); };
  *{IO::Handle::printObject} = sub { printObject(@_); };
}

sub printObject {
  my ( $fh, $obj ) = @_;

  $fh->print( "OBJECT=", _walker( $obj, 0 ), ";\n" );
}

sub _walker {
  my ( $obj, $ts ) = @_;

#  my $ref = scalar($obj);
#  my $ref = ref($obj);
  my ($type) = $obj =~ /($match)/o;

  if( defined($type) && exists( $dispatch{$type} ) ) {
    return $dispatch{$type}->( $obj, $ts );
  } else {
    return ($obj);
  }
}

sub _printArray {
  my ( $list, $ts ) = @_;

  my $tabs = ' ' x ( $ts * 2 );
  my $retval = "$list\[  <" . scalar( @{$list} ) . " elements>\n";
  foreach my $item ( @{$list} ) {
    $retval .= "$tabs  ";
    $retval .= _walker( $item, $ts + 1 );
    $retval .= ",\n";
  }
  $retval .= "$tabs]";
  return $retval;
}

sub _printCode {
  my ( $code, $ts ) = @_;

  my $tabs = ' ' x ( $ts * 2 );
  my $deparse = B::Deparse->new( '-p', '-sC' );
  my $body = $deparse->coderef2text($code);

  my @lines = split( /\n/, $body );
  pop(@lines);
  shift(@lines);
  foreach my $ln (@lines) {
    $ln =~ s/^\s*//o;
    $ln = "$tabs  $ln";
  }
  $body = join( "\n", @lines );

  return "$code=sub\{\n$body\n$tabs}";
}

sub _printHash {
  my ( $hash, $ts ) = @_;

  my $tabs = ' ' x ( $ts * 2 );

  my $longest = 0;
  foreach my $key ( keys %{$hash} ) {
    $longest = length($key) if( length($key) > $longest );
  }

  my $retval = "$hash\{  <" . ( scalar keys %{$hash} ) . " keys>\n";
  foreach my $item ( sort keys %{$hash} ) {
    $retval .= "$tabs  $item" . " " x ( $longest - length($item) ) . " => ";
    $retval .= _walker( $hash->{$item}, $ts + 1 );
    $retval .= ",\n";
  }
  $retval .= "$tabs}";
}

sub _printScalar {
  my ($scalar) = @_;
  return ${$scalar};
}

