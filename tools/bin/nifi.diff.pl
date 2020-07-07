#! /usr/bin/env perl

use 5.020;
use warnings;
use autodie;

use Getopt::Long;
use Hash::Diff;
use Term::ANSIColor qw( :constants );
use XML::LibXML;

use Toolkit;

my %opts;
if ( !GetOptions( \%opts, 'baseline=s', 'changed=s', ) ) {
  die("Invalid incantation\n");
}

my %dispatch = (
  processGroups => \&processProcessGroups,
  processors    => \&processProcessor,
  connections   => \&processConnections,

);

my %REGISTRY;

main();
exit(0);

sub main {

  my $baseline = processTemplate( $opts{'baseline'} );

  #  printObject($baseline);

  my $changed = processTemplate( $opts{'changed'} );

  #  printObject($changed);
  compareTemplate( $baseline, $changed );
}

sub compareTemplate {
  my ( $ba, $ac ) = @_;

  if ( exists( $ba->{'_template'}{'_cs'} )
    || exists( $ac->{'_template'}{'_cs'} ) )
  {
    compareControllerServices( $ba->{'_template'}{'_cs'},
      $ac->{'_template'}{'_cs'} );
  }

  if ( exists( $ba->{'_template'}{'_processGroups'} )
    || exists( $ac->{'_template'}{'_processGroups'} ) )
  {
    compareProcessGroup(
      '',
      $ba->{'_template'}{'_processGroups'},
      $ac->{'_template'}{'_processGroups'}
    );
  }

}

sub compareControllerServices {
  my ( $ba, $ac ) = @_;

  my %base   = map { $_->{'_name'} => $_ } @{$ba};
  my %actual = map { $_->{'_name'} => $_ } @{$ac};
  foreach my $cs ( sort keys %base ) {
    if ( exists( $actual{$cs} ) ) {
      compareProperties( $cs, $base{$cs}{'_prop'}, $actual{$cs}{'_prop'} );
      delete( $base{$cs} );
      delete( $actual{$cs} );
    }
  }

  if ( scalar( keys %base ) || scalar( keys %actual ) ) {
    message("Controller Services");
    if ( scalar( keys %base ) ) {
      foreach ( keys %base ) {
        say( white("<  $_") );
      }
    }
    say( '-' x 10 );
    if ( scalar( keys %actual ) ) {
      foreach ( keys %actual ) {
        say( magenta(">  $_") );
      }
    }
  }
}

sub compareProperties {
  my ( $label, $ba, $ac ) = @_;

  my %base   = %{$ba};
  my %actual = %{$ac};

  my @before;
  my @after;

  my %patternProperty = (
    'AWS Credentials Provider service' => '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
  );

  foreach my $prop ( sort keys %base ) {
    if ( exists( $actual{$prop} ) ) {
      if( exists($patternProperty{$prop}) ){
        my $pattern = $patternProperty{$prop};
        if( ($base{$prop} !~ /^$pattern$/) || ($actual{$prop} !~ /^$pattern$/) ){
        push( @before, "$prop => $base{$prop}" );
        push( @after,  "$prop => $actual{$prop}" );
        }
      }else{
      my $bval = $REGISTRY{$base{$prop}} || $base{$prop};
      my $aval = $REGISTRY{$actual{$prop}} || $actual{$prop};
      if ( $bval ne $aval ) {
        push( @before, "$prop => $base{$prop}" );
        push( @after,  "$prop => $actual{$prop}" );
      }
      }
      delete( $base{$prop} );
      delete( $actual{$prop} );
    }
  }

  if ( scalar( keys %base ) ) {
    push( @before, "$_ => $base{$_}" ) foreach ( keys %base );
  }
  if ( scalar( keys %actual ) ) {
    push( @after, "$_ => $actual{$_}" ) foreach ( keys %actual );
  }

  if ( scalar(@before) || scalar(@after) ) {
    message("Property Changes for [$label]");

    if ( scalar(@before) ) {
      say( white("  < $_") ) foreach @before;
      say( '  ' . '-' x 10 ) if ( scalar(@after) );
    }
    if ( scalar(@after) ) {
      say( magenta("  > $_") ) foreach @after;
    }
  }

}

sub compareProcessGroup {
  my ( $label, $ba, $ac ) = @_;

  my %base   = map { $_->{'_name'} => $_ } @{$ba};
  my %actual = map { $_->{'_name'} => $_ } @{$ac};

  foreach my $pg ( sort keys %base ) {
    if ( exists( $actual{$pg} ) ) {
      compareContent(
        "$label/$pg",
        $base{$pg}{'_content'},
        $actual{$pg}{'_content'}
      );
      delete( $base{$pg} );
      delete( $actual{$pg} );
    }
  }

  if ( scalar( keys %base ) || scalar( keys %actual ) ) {
    message("Process Groups");
    if ( scalar( keys %base ) ) {
      foreach ( keys %base ) {
        say( white("<  $_") );
      }
    }
    say( '-' x 10 );
    if ( scalar( keys %actual ) ) {
      foreach ( keys %actual ) {
        say( magenta(">  $_") );
      }
    }
  }

}

sub compareContent {
  my ( $label, $ba, $ac ) = @_;

  my %base   = %{$ba};
  my %actual = %{$ac};

  foreach my $content ( sort keys %base ) {
    if ( exists( $actual{$content} ) ) {
      if ( $content eq '_processGroups' ) {
        compareProcessGroup( $label, $base{$content}, $actual{$content} );
      } elsif ( $content eq '_processors' ) {
        compareProcessors( $label, $base{$content}, $actual{$content} );
      } elsif ( $content eq '_connections' ) {
        compareConnections( $label, \%base, \%actual );
      } else {
        quick( content => $content );
      }

      delete( $base{$content} );
      delete( $actual{$content} );
    }
  }

  if ( scalar( keys %base ) || scalar( keys %actual ) ) {
    message("Content for: [$label]");
    if ( scalar( keys %base ) ) {
      foreach ( keys %base ) {
        say( white("<  $_") );
      }
    }
    say( '-' x 10 );
    if ( scalar( keys %actual ) ) {
      foreach ( keys %actual ) {
        say( magenta(">  $_") );
      }
    }
  }
}

sub compareProcessors {
  my ( $label, $ba, $ac ) = @_;

  my %base   = map { $_->{'_name'} => $_ } @{$ba};
  my %actual = map { $_->{'_name'} => $_ } @{$ac};
  foreach my $cs ( sort keys %base ) {
    if ( exists( $actual{$cs} ) ) {
      compareProperties(
        "$label/$cs",
        $base{$cs}{'_prop'},
        $actual{$cs}{'_prop'}
      );
      delete( $base{$cs} );
      delete( $actual{$cs} );
    }
  }

  if ( scalar( keys %base ) || scalar( keys %actual ) ) {
    message("Processors for: [$label]");
    if ( scalar( keys %base ) ) {
      foreach ( keys %base ) {
        say( white("<  $_") );
      }
      say( '-' x 10 ) if ( scalar( keys %actual ) );
    }
    if ( scalar( keys %actual ) ) {
      foreach ( keys %actual ) {
        say( magenta(">  $_") );
      }
    }
  }
}

sub compareConnections {
  my ( $label, $ba, $ac ) = @_;
  my %base;
  my %actual;
  my @conn = @{ $ba->{_connections} };
  my @proc = @{ $ba->{_processors} };

  my %lookup = map { $_->{_id} => $_ } @proc;
  foreach my $conn (@conn) {
    my ( $s, $d, $r ) = @{$conn}{ '_source', '_destination', '_relation' };
    $s = $lookup{$s}{_name} || 'unknown';
    $d = $lookup{$d}{_name} || 'unknown';
    $base{"$s;$d;$r"} = "$s -> $r -> $d";
  }

  @conn = @{ $ac->{_connections} };
  @proc = @{ $ac->{_processors} };

  %lookup = map { $_->{_id} => $_ } @proc;
  foreach my $conn (@conn) {
    my ( $s, $d, $r ) = @{$conn}{ '_source', '_destination', '_relation' };
    $s = $lookup{$s}{_name} || 'unknown';
    $d = $lookup{$d}{_name} || 'unknown';
    $actual{"$s;$d;$r"} = "$s -> $r -> $d";
  }

  my @before;
  my @after;
  foreach ( keys %base ) {
    if ( exists( $actual{$_} ) ) {
      if ( $base{$_} ne $actual{$_} ) {
        push( @before, $base{$_} );
        push( @after,  $actual{$_} );
      }
      delete( $base{$_} );
      delete( $actual{$_} );
    }
  }

  if ( scalar( keys %base ) ) {
    push( @before, "$_ => $base{$_}" ) foreach ( keys %base );
  }
  if ( scalar( keys %actual ) ) {
    push( @after, "$_ => $actual{$_}" ) foreach ( keys %actual );
  }

  if ( scalar(@before) || scalar(@after) ) {
    message("Connection Changes for [$label]");

    if ( scalar(@before) ) {
      say( white("  < $_") ) foreach @before;
      say( '  ' . '-' x 10 ) if ( scalar(@after) );
    }
    if ( scalar(@after) ) {
      say( magenta("  > $_") ) foreach @after;
    }
  }

}

sub processTemplate {
  my ($filename) = @_;

  my $xp   = XML::LibXML->new();
  my $dom  = $xp->parse_file($filename);
  my $root = $dom->firstChild();
  if ( $root->nodeName() ne 'template' ) {
    die('unsupported nifi template file');
  }

  my %report;

  my ($tmp) = $root->findnodes('./description/text()');
  $report{'_template'}{'description'} = defined $tmp ? $tmp->nodeValue() : '';

  ($tmp) = $root->findnodes('./id/text()');
  $report{'_template'}{'id'} = defined $tmp ? $tmp->nodeValue() : '';

  ($tmp) = $root->findnodes('./groupId/text()');
  $report{'_template'}{'groupId'} = defined $tmp ? $tmp->nodeValue() : '';

  ($tmp) = $root->findnodes('./name/text()');
  $report{'_template'}{'name'} = defined $tmp ? $tmp->nodeValue() : '';

  ($tmp) = $root->findnodes('./timestamp/text()');
  $report{'_template'}{'timestamp'} = defined $tmp ? $tmp->nodeValue() : '';

  my @children = $root->findnodes('./snippet/controllerServices');
  foreach my $node (@children) {
    my $result = processControllerService( $node );
    push( @{ $report{'_template'}{'_cs'} }, $result );
  }

  @children = $root->findnodes('./snippet/processGroups');
  foreach my $node (@children) {
    my $result = processProcessGroups( $node );
    push( @{ $report{'_template'}{'_processGroups'} }, $result );
  }

  return wantarray ? %report : \%report;
}

sub processControllerService {
  my ($node) = @_;

  my %retval = (
    '_id'       => getNodeValue( $node, './id/text()' ),
    '_parent'   => getNodeValue( $node, './parentGroupId/text()' ),
    '_comments' => getNodeValue( $node, './comments/text()' ),
    '_name'     => getNodeValue( $node, './name/text()' ),
    '_type'     => getNodeValue( $node, './type/text()' ),
  );
  $REGISTRY{ $retval{'_id'} } = $retval{'_name'};

  my %props;
  my @properties = $node->findnodes('./properties/entry');
  foreach my $prop (@properties) {
    $props{ getNodeValue( $prop, './key/text()' ) }
        = getNodeValue( $prop, './value/text()' );
  }
  $retval{'_prop'} = \%props;

  return wantarray ? %retval : \%retval;
}

sub processProcessGroups {
  my ($node) = @_;

  my %retval = (
    '_id'       => getNodeValue( $node, './id/text()' ),
    '_parent'   => getNodeValue( $node, './parentGroupId/text()' ),
    '_comments' => getNodeValue( $node, './comments/text()' ),
    '_name'     => getNodeValue( $node, './name/text()' ),
    '_type'     => getNodeValue( $node, './type/text()' ),
  );
  $REGISTRY{ $retval{'_id'} } = $retval{'_name'};

  my %content;
  my @contents = $node->findnodes('./contents/*');
  foreach my $item (@contents) {
    my $name = $item->nodeName();
    if ( exists( $dispatch{$name} ) ) {
      push( @{ $content{"_$name"} }, $dispatch{$name}->($item) );
    } else {
      quick( 'unsupported content', $name );
    }
  }
  $retval{'_content'} = \%content;

  #  return wantarray ? %retval : \%retval;
  return \%retval;
}

sub getNodeValue {
  my ($tmp) = $_[0]->findnodes( $_[1] );
  return defined $tmp ? $tmp->nodeValue() : '';
}

sub processProcessor {
  my ($node) = @_;

  my %retval = (
    '_id'     => getNodeValue( $node, './id/text()' ),
    '_parent' => getNodeValue( $node, './parentGroupId/text()' ),
    '_state'  => getNodeValue( $node, './state/text()' ),
    '_name'   => getNodeValue( $node, './name/text()' ),
    '_type'   => getNodeValue( $node, './type/text()' ),
  );
  $REGISTRY{ $retval{'_id'} } = $retval{'_name'};

  my %props;
  my @properties = $node->findnodes('./config/properties/entry');
  foreach my $prop (@properties) {
    $props{ getNodeValue( $prop, './key/text()' ) }
        = getNodeValue( $prop, './value/text()' );
  }
  $retval{'_prop'} = \%props;

  return \%retval;
}

sub processConnections {
  my ($node) = @_;

  my %retval = (
    '_id'          => getNodeValue( $node, './id/text()' ),
    '_source'      => getNodeValue( $node, './source/id/text()' ),
    '_destination' => getNodeValue( $node, './destination/id/text()' ),
    '_relation'    => getNodeValue( $node, './selectedRelationships/text()' ),
    '_name'        => getNodeValue( $node, './name/text()' ),
  );
  $REGISTRY{ $retval{'_id'} } = $retval{'_name'};

  return \%retval;
}

=pod
sub quick {
  my $autoflush = $|;
  $| = 1;
  print( "[", join( "][", map { yellow($_) } @_ ), "]\n" );
  $| = $autoflush;
}

sub yellow {
  my ( $str, $format ) = @_;
  return YELLOW . BOLD . $str . RESET;
}

sub magenta {
  my ( $str, $format ) = @_;
  return MAGENTA . $str . RESET;
}

sub white {
  my ( $str, $format ) = @_;
  return WHITE . BOLD . $str . RESET;
}

sub message {
  my $tmstmp = "====> " . scalar( localtime(time) );
  print( "\n", join( "\n", $tmstmp, @_ ), "\n" );
}
=cut
