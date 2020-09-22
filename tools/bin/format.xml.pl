#!/usr/bin/env perl

use 5.020;
use warnings;
use autodie;

use Getopt::Long;
use XML::LibXML;

use Utilities qw( message quick );

my %opts;
if ( !GetOptions( \%opts, 'infile=s', 'commit' ) ) {
  die("Invalid incantation\n");
}

my %C = (
  line_width      => 120,
  indent          => 2,
  leader          => " ",
  quote_char      => '"',
  expand_empty    => 1,
  max_blank_lines => 1,
);

my %dispatch = (
  9  => \&renderDocument,
  1  => \&renderElement,
  2  => \&renderAttribute,
  18 => \&renderNamespace,
  3  => \&renderText,
);

my $DEBUG = 0;

main();
exit(0);

sub main {
  foreach my $req (qw( infile )) {
    die("must specify: $req")
        unless ( exists( $opts{$req} ) && -f $opts{$req} );
  }

  my $document = $opts{'infile'};

  my $parser = XML::LibXML->new;

  #  $parser->keep_blanks(0);
  my $root = undef;
  eval { $root = $parser->parse_file($document); };
  if ($@) {
    message( "Parse Errors:", $@ );
    exit(1);
  }

  if ( defined($root) ) {
    my $formatted = formatNode($root);

    if ( exists( $opts{'commit'} ) ) {
      open(my $fh, '>', $opts{'infile'});
      $fh->print($formatted,"\n");
      close($fh);
    } else {
      say($formatted);
    }
  }
}

sub formatNode {
  my ( $node, $lvl ) = @_;

  $lvl = 0 unless ($lvl);

  my $retval = '';

  if ( exists( $dispatch{ $node->nodeType() } ) ) {
    $retval .= $dispatch{ $node->nodeType() }->( $node, $lvl );
  }

  return $retval;
}

sub renderDocument {
  my ( $node, $lvl ) = @_;

  my $retval = '';
  $retval .= sprintf(
    "<?xml version=%s%s%s encoding=%s%s%s?>\n",
    $C{'quote_char'}, $node->version(),  $C{'quote_char'},
    $C{'quote_char'}, $node->encoding(), $C{'quote_char'}
  );

  my $child = $node->firstChild();
  $retval .= $dispatch{ $child->nodeType() }->( $child, $lvl );
  return $retval;
}

sub renderElement {
  my ( $node, $lvl ) = @_;

  my $retval = '';

  my $name     = $node->nodeName();
  my $name_len = length($name);

  my @line = ( $C{'leader'} x ( $C{'indent'} * $lvl ), '<', $name );
  my $line_len = lineLength( \@line );

  if ( $node->hasAttributes() ) {

    my @attrList = $node->attributes();
    foreach my $attr ( sort { $a->nodeType() cmp $b->nodeType() } @attrList )
    {
      my $value = $dispatch{ $attr->nodeType() }->($attr);
      my $len   = length($value);
      if ( $line_len + $len < $C{'line_width'} ) {
        push( @line, ' ', $value );
        $line_len = lineLength( \@line );
      } else {
        $retval .= join( '', @line, "\n" );
        @line = ( $C{'leader'} x ( $C{'indent'} * $lvl + $name_len + 2 ),
          $value );
        $line_len = lineLength( \@line );
      }
    }
  }
  $retval .= join( '', @line );

  my @children = $node->childNodes();
  if ( scalar(@children) ) {
    my $terminus = '>';
    my $leader = $C{'leader'} x ( $C{'indent'} * $lvl );
    if ( scalar(@children) == 1 ) {
      $leader = '';
    }

    $retval .= $terminus;
    foreach my $child ( $node->childNodes() ) {
      my $childType = $child->nodeType();
      my $value = $dispatch{$childType}->( $child, $lvl + 1 );
      $retval .= $value;
    }
    $retval .= sprintf( '%s</%s>', $leader, $name );
  } else {
    if ( $C{'expand_empty'} ) {
      $retval .= "></$name>";
    } else {
      $retval .= "/>";
    }
  }

  return $retval;
}

sub renderText {
  my ( $node, $lvl ) = @_;
  my $str = $node->data();

  if ( $str =~ /^\s*$/m ) {
    my @data = split( /\r?\n/, $str );
    my $mbl = $C{'max_blank_lines'};
    if ( scalar(@data) > $mbl + 1 ) {
      @data = map {''} 0 .. $mbl;
    } else {
      pop(@data);
    }
    $str = join( "\n", @data ) . "\n";
  }

  return $str;
}

sub renderNamespace {
  my ( $node, $lvl ) = @_;

  return sprintf( '%s=%s%s%s',
    $node->name(), $C{'quote_char'}, $node->value(), $C{'quote_char'} );
}

sub renderAttribute {
  my ( $node, $lvl ) = @_;

  my $name
      = $node->prefix()
      ? $node->prefix() . ':' . $node->name()
      : $node->name();

  return sprintf( '%s=%s%s%s',
    $name, $C{'quote_char'}, $node->value(), $C{'quote_char'} );
}

sub lineLength($) {
  my $retval = 0;
  foreach my $item ( @{ $_[0] } ) {
    $retval += length($item);
  }
  return $retval;
}

__END__ 

=head1 NAME

validate.xml.pl - [simple xml schema validation check]

=head1 VERSION

This documentation refers to validate.xml.pl version 0.0.1

=head1 USAGE

    validate.xml.pl --infile=s --schema=s

=head1 REQUIRED ARGUMENTS

=over

=item --infile=s

Specifies the path to the xml file to validate.

=item --schema=s

Specifies the schema to do the validation against.

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

