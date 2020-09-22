#!/usr/bin/env perl

use 5.020;
use warnings;
use autodie;

use Getopt::Long;
use XML::LibXML;

use Toolkit;

my %opts;
if ( !GetOptions( \%opts, 'infile=s', 'outfile=s' ) ) {
  die("Invalid incantation\n");
}

main();
exit(0);

sub main {

  my %elements;

  my $xp  = XML::LibXML->new();
  my $doc = $xp->parse_file( $opts{'infile'} );
  scan_document( $doc->documentElement(), \%elements );
  my $schema = generate_schema( \%elements );
  message( 'schema' => $schema );

  if( exists($opts{'outfile'}) ){
  open(my $fh, '>', $opts{'outfile'});
  $fh->print($schema);
  close($fh);
  }

}

sub generate_schema {
  my ($library) = @_;

  my @retval = (
    "<?xml version='1.0'?>",
    "<xs:schema xmlns:xs='http://www.w3.org/2001/XMLSchema'>",
  );

  foreach my $name ( sort{ $library->{$a}{'_order'} <=> $library->{$b}{'_order'} } keys %{$library} ) {
    push( @retval, "" );
    my $element = $library->{$name};
    printObject($element);

    my $value = join( '', @{ $element->{'_value'} } );
    my $type = getDataType($value);

    my $complex |= scalar( @{ $element->{'_child'} } ) > 0     ? 1 : 0;
    $complex    |= scalar( keys %{ $element->{'_attr'} } ) > 0 ? 2 : 0;
    if ( $complex == 0 ) {
      push( @retval,
        "  <xs:element name='$element->{'_name'}' type='$type'/>" );
    } elsif ( $complex == 2 ) {
      push( @retval, "  <xs:element name='$element->{'_name'}' type='$name\_type'/>" );
      push( @retval, "  <xs:complexType name='$name\_type'>" );
      foreach my $attr ( sort keys %{ $element->{'_attr'} } ) {
        my $attrValue = join( '', @{ $element->{'_attr'}{$attr} } );
        my $attrType = getDataType($attrValue);
        push( @retval, "    <xs:attribute name='$attr' type='$attrType'/>" );
      }
      push( @retval, "  </xs:complexType>" );
    } elsif ( $complex & 1 ) {
      push( @retval, "  <xs:element name='$element->{'_name'}'>" );
      push( @retval, "    <xs:complexType>" );
      push( @retval, "      <xs:sequence>" );
      foreach my $child ( @{ $element->{'_child'} } ) {
        my $bounded = $element->{'_bound'}{$child} > 1 ? " maxOccurs='unbounded'" : '';
        push( @retval, "        <xs:element ref='$child'$bounded/>" );
      }
      push( @retval, "      </xs:sequence>" );

      foreach my $attr ( sort keys %{ $element->{'_attr'} } ) {
        my $attrValue = join( '', @{ $element->{'_attr'}{$attr} } );
        my $attrType = getDataType($attrValue);
        push( @retval, "      <xs:attribute name='$attr' type='$attrType'/>" );
      }

      push( @retval, "    </xs:complexType>" );
      push( @retval, "  </xs:element>" );
    }

  }

  push( @retval, "</xs:schema>" );
  return join( "\n", @retval );
}

sub getDataType {
  my ($value) = @_;
  my $type = 'xs:string';
  $type = 'xs:decimal' if ( $value =~ /^[\+\-\.0-9]+$/ );
  $type = 'xs:integer' if ( $value =~ /^[\+\-0-9]+$/ );
  $type = 'xs:boolean' if ( $value =~ /^(true|false)+$/i );
  return $type;
}

my $order = 0; 
sub scan_document {
  my ( $node, $library ) = @_;

  my $element = undef;
  my $name    = $node->nodeName();
  if ( !exists( $library->{$name} ) ) {
    $element = { _name => $name, _value => [], _attr => {}, _child => [], _order=>$order++ };
    $library->{$name} = $element;
  }
  $element = $library->{$name};

  my @children = $node->childNodes();
  my @nonBlank = $node->nonBlankChildNodes();
  if ( scalar(@children) == scalar(@nonBlank) ) {
    my $value = $node->textContent();
    my %range = map { $_ => undef } @{ $element->{'_value'} };
    if ( $value =~ /^(true|false)$/i ) {
      $range{$value} = undef;
    } else {
      $range{$_} = undef foreach split( //, $value );
    }
    $element->{'_value'} = [ keys %range ];
  }

  my $attributes = $element->{'_attr'};
  foreach my $attr ( $node->attributes() ) {
    my $attrName = $attr->nodeName();
    my %range    = map { $_ => undef } @{ $attributes->{$attrName} };
    my $value    = $attr->value();
    if ( $value =~ /^(true|false)$/i ) {
      $range{$value} = undef;
    } else {
      $range{$_} = undef foreach split( //, $value );
    }
    $attributes->{$attrName} = [ keys %range ];
  }

  foreach my $child (@nonBlank) {

    if ( $child->nodeType() == XML_ELEMENT_NODE ) {
      my $childName = $child->nodeName();
      my %known = map { $_ => undef } @{ $element->{'_child'} };
      if ( !exists( $known{$childName} ) ) {
        push( @{ $element->{'_child'} }, $childName );
      }

      $element->{'_bound'}{$childName}++;

      scan_document( $child, $library );
    }
  }
}

__END__ 

=head1 NAME

build.schema.pl - [description here]

=head1 VERSION

This documentation refers to build.schema.pl version 0.0.1

=head1 USAGE

    build.schema.pl [options]

=head1 REQUIRED ARGUMENTS

=over

None

=back

=head1 OPTIONS

=over

None

=back

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

Requires no configuration files or environment variables.


=head1 DEPENDENCIES

None.


=head1 BUGS

None reported.
Bug reports and other feedback are most welcome.


=head1 AUTHOR

Andrew Pressel C<< apressel@nextgenfed.com >>


=head1 COPYRIGHT

Copyright (c) 2017, Andrew Pressel C<< <apressel@nextgenfed.com> >>. All rights reserved.

This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
(see http://www.perl.com/perl/misc/Artistic.html)


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

