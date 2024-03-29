package Utilities;

use strict;
use 5.020;
use base qw( Exporter );
use File::Basename;
use Getopt::Long;
use IO::File;
use POSIX qw( strftime );
use Term::ANSIColor qw( :constants color );
use Term::ReadKey;

use StructurePrinter;

our %EXPORT_TAGS = (
  COMPARE => [qw( compareHash compareArray )],
  LOG     => [qw( startlog )],
  MISC    => [
    qw( quick message message_err message_alert walker wrapper reload_module backspace)
  ],
  SQL   => [qw( query variables )],
  STATS => [qw( makeAverager permute mean stddev )],
  TIME  => [qw( convertSeconds )],
  ANSI  => [
    qw( makeColor clrscr grey orange red green yellow blue magenta white faint )
  ],
  SPINNERS => [qw( makeSpinner )],
  DATA     => [qw( dump_table dump_tree dump_note )],
  ALL      => [],
);

our @EXPORT_OK;
push( @EXPORT_OK, map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS );

our $VERSION = '0.29.0';

our %MTIME;

sub clrscr {
  print "\033[2J\033[0;0H";
}

sub makeSpinner {
  my ( $base, $steps ) = @_;
  $base  = '0x1F550' unless ($base);
  $steps = 12        unless ($steps);

  $base = hex($base);
  my $state = 0;

  open( my $fh, ">&STDOUT" ) or die("couldn't dup STDOUT: [$!]");
  binmode( $fh, ':utf8' );
  $fh->autoflush();

  return sub {
    local $| = 1;
    $fh->print( "\r", chr( $base + $state ) );
    $state = ( $state + 1 ) % $steps;
  }
}

sub permute {
  my ( $ref, $sz ) = @_;

  $sz = scalar( @{$ref} ) unless ( defined($sz) );
  if ( $sz == 1 ) {
    quick( @{$ref} );
    return;
  }

  foreach my $i ( 0 .. ( $sz - 1 ) ) {
    permute( $ref, $sz - 1 );

    if ( $sz % 2 == 1 ) {
      @{$ref}[ 0, $sz - 1 ] = @{$ref}[ $sz - 1, 0 ];
    } else {
      @{$ref}[ $i, $sz - 1 ] = @{$ref}[ $sz - 1, $i ];
    }
  }
}

sub clean {
  my ($str) = @_;
  $str =~ s/\x1b\[\d+m//go;
  return $str;
}


sub dump_note{
  my %args = @_;

  open( my $fh, ">&STDOUT" ) or die("couldn't dup STDOUT: [$!]");
  binmode( $fh, ':utf8' );

  my $title = $args{'title'};
  my @data;
  if( ref($args{'data'}) ){
    @data = @{$args{'data'}};
  }else{
    @data = split($/, $args{'data'});
  }

  my ( $x, $y, $xp, $yp ) = GetTerminalSize();
  my $sz = scalar(@data);
  my $w = length($sz);

  my $gutter = 2 + $w;
  my $wide = $x-$gutter-1;

  my $gcolor = makeColor(238);
  my $tcolor = makeColor(255);
  $fh->say($gcolor->(sprintf('%s%s%s', "\x{2500}"x$gutter, "\x{252C}", "\x{2500}"x$wide)));
  $fh->say(sprintf(" %${w}s %s %s", '', $gcolor->("\x{2502}"), $tcolor->($title)));
  $fh->say($gcolor->(sprintf('%s%s%s', "\x{2500}"x$gutter, "\x{253C}", "\x{2500}"x$wide)));
  foreach my $idx (0 .. $#data){
    $fh->print($gcolor->(sprintf(" %${w}s %s ", $idx+1, "\x{2502}")));
    $fh->say($data[$idx]);
  }
  $fh->say($gcolor->(sprintf('%s%s%s', "\x{2500}"x$gutter, "\x{2534}", "\x{2500}"x$wide)));

}

sub dump_tree {
  my ( $ref, $args, $fullPath, $pre ) = @_;

  $args     = {} unless ( defined($args) );
  $pre      = '' unless ( defined($pre) );
  $fullPath = '' unless ( defined($fullPath) );

  my $idx = 0;
  my $sz  = scalar keys %{$ref};
  foreach my $key ( sort keys %{$ref} ) {
    $idx++;
    my $isFolder = scalar( keys %{ $ref->{$key} } );
    my $name     = $isFolder   ? green("$key") : $key;
    my $next     = $idx == $sz ? '    '        : '│   ';
    my $lead     = $idx == $sz ? '└── '        : '├── ';

    next if ( exists( $args->{'d'} ) && !$isFolder );
    if ( exists( $args->{'match'} ) ) {
      next if ( !$isFolder && ( $key !~ /$args->{'match'}/ ) );
    }

    if ( exists( $args->{'full'} ) ) {
      say("${pre}${lead}${fullPath}/${name}");

    } else {
      say("${pre}${lead}${name}");
    }

    dump_tree( $ref->{$key}, $args, "$fullPath/$name", "${pre}${next}" );
  }
}

sub dump_table {
  my @retval = build_table(@_);
  my %args   = @_;
  my $rows   = scalar( @{ $args{'table'} } ) - 1;

  open( my $fh, ">&STDOUT" ) or die("couldn't dup STDOUT: [$!]");
  binmode( $fh, ':utf8' );
  $fh->autoflush();
  $fh->say( join( "\n", @retval, "$rows Rows Affected" ) );
}

sub build_table {
  my %args = @_;

  my @base = @{ $args{'table'} };
  my @table;

  my @widths;
  foreach my $row ( 0 .. $#base ) {
    my $ref  = $base[$row];
    my $cols = $#{$ref};

    my @rowRef;
    push( @table, \@rowRef );

    foreach my $i ( 0 .. $cols ) {
      my @lines = split( /\n/, $ref->[$i] );
      my $first = shift(@lines);

      my $clean = $first;
      $clean =~ s/\x1b\[[0-9;]+m//g;
      my $tmp = length($clean);
      $widths[$i] = $tmp if ( $tmp > $widths[$i] );
      push( @rowRef, [ $tmp, "$ref->[$i]" ] );

    }
  }

  my @retval;
  my $hdr = '+-' . join( '-+-', map { '-' x $_ } @widths ) . '-+';

  # front + links + end
  my $cols = 4 + 3 * ( scalar(@widths) - 1 );
  map { $cols += $_ } @widths;

  my ( $x, $y, $xp, $yp ) = GetTerminalSize();

  if ( $cols > $x ) {
    @retval = _vertTable( $x, \@table, \@widths );
  } else {
    my $border = grey(
      "\x{251C}\x{2500}"
          . join(
        "\x{2500}\x{253C}\x{2500}", map { "\x{2500}" x $_ } @widths
          )
          . "\x{2500}\x{2524}"
    );
    push(
      @retval,
      grey(
        "\x{250C}\x{2500}"
            . join( "\x{2500}\x{252C}\x{2500}",
          map { "\x{2500}" x $_ } @widths )
            . "\x{2500}\x{2510}"
      ),
      _wideTable( $border, \@table, \@widths ),
      grey(
        "\x{2514}\x{2500}"
            . join( "\x{2500}\x{2534}\x{2500}",
          map { "\x{2500}" x $_ } @widths )
            . "\x{2500}\x{2518}"
      ),
    );
  }

  return wantarray ? @retval : join( "\n", @retval );
}

sub _vertTable {
  my ( $wide, $tblRef, $wideRef ) = @_;

  my @table = @{$tblRef};
  my @retval;

  my $hdrWide = 0;
  my $hdr     = shift(@table);
  foreach my $ref ( @{$hdr} ) {
    my $tmp = length( $ref->[1] );
    $hdrWide = $tmp if ( $tmp > $hdrWide );
  }

  my $i     = int( scalar(@table) / 10 ) + 1;
  my $count = 1;
  foreach my $row (@table) {
    my $rowNum = ' ' x ( $i - length($count) + 1 ) . "$count row ";
    my $len    = ( $wide - ( length($rowNum) ) ) / 2;
    my $banner = '*' x $len . $rowNum . '*' x $len;
    push( @retval, substr( $banner, 0, $wide - 1 ) );

    foreach my $col ( 0 .. ( scalar( @{$hdr} ) - 1 ) ) {
      my $lead = $hdr->[$col][1];
      my @line = split( /\n/, $row->[$col][1] );
      foreach my $ln (@line) {
        push( @retval, sprintf( "%$hdrWide\s : %s", $lead, $ln ) );
        $lead = '';
      }
    }
    $count++;
  }

  return wantarray ? @retval : join( "\n", @retval );
}

sub _wideTable {
  my ( $hdr, $tblRef, $wideRef ) = @_;
  my @table  = @{$tblRef};
  my @widths = @{$wideRef};

  my @retval;

  my $row = shift @table;
  push(
    @retval,
    grey("\x{2502}") . " "
        . join(
      " " . grey("\x{2502}") . " ",
      map { yellow( $row->[$_][1] ) . " " x ( $widths[$_] - $row->[$_][0] ) }
          0 .. ( $#{$row} )
        )
        . " "
        . grey("\x{2502}")
  );
  push( @retval, $hdr );

  foreach $row (@table) {
    my $limit = 1;
    for ( my $bix = 0; $bix < $limit; $bix++ ) {
      my @buffer;
      foreach my $idx ( 0 .. $#{$row} ) {
        my @lines = split( /\n/, $row->[$idx][1] );
        my $sz    = scalar(@lines);
        $limit = $sz if ( $sz > $limit );

        if ( $sz > $bix ) {
          my $clean = $lines[$bix];
          $clean =~ s/\x1b\[[0-9;]+m//g;
          my $tmp = length($clean);
          push( @buffer, $lines[$bix] . ' ' x ( $widths[$idx] - $tmp ) );
        } else {
          push( @buffer, ' ' x $widths[$idx] );
        }
      }
      push( @retval,
              grey("\x{2502} ")
            . join( grey(" \x{2502} "), @buffer )
            . grey(" \x{2502}") );
    }
  }

  return wantarray ? @retval : join( "\n", @retval );
}

sub backspace {
  my ($orig) = @_;

  my @tmp = unpack( "C*", reverse($orig) );
  my $del = 0;
  my @new;

  foreach my $char (@tmp) {
    if ( ( $char == 127 ) || ( $char == 8 ) ) {
      $del++;
      next;
    } elsif ( $del != 0 ) {
      $del--;
      next;
    } else {
      push( @new, $char );
    }
  }

  return pack( "C*", reverse(@new) );
}

sub reload_module {
  my ($module) = @_;
  $module =~ s/\:\:/\//go;
  $module .= '.pm';

  return unless ( exists( $INC{$module} ) );

  my $file  = $INC{$module};
  my $mtime = ( stat $file )[9];
  $MTIME{$file} = $^T unless ( exists( $MTIME{$file} ) );

  if ( $mtime > $MTIME{$file} ) {
    delete( $INC{$module} );
    require($module);
    $MTIME{$file} = $mtime;
  }
}

sub makeColor {
  my ($color) = @_;
  $color = "ansi$color" if ( $color =~ /^\d+$/ );
  return sub {
    return color($color) . $_[0] . RESET;
  }
}

*grey    = makeColor('ansi238');
*orange  = makeColor('ansi136');
*red     = makeColor('red');
*green   = makeColor('green');
*yellow  = makeColor('ansi226');
*blue    = makeColor('blue');
*magenta = makeColor('magenta');
*white   = makeColor('ansi255');
*faint   = makeColor('faint');

sub convertSeconds {
  my ($seconds) = @_;

  my $hours = int( $seconds / 3600 );
  $seconds = $seconds % 3600;    # remove the hours

  my $minutes = int( $seconds / 60 );
  $seconds = $seconds % 60;      # remove the minutes

  return sprintf( "%02d:%02d:%02d", $hours, $minutes, $seconds );
}

sub makeAverager {
  my $mean   = 0;
  my $count  = 0;
  my $moment = 0;

  return sub {
    my $stddev = 0;
    foreach my $value (@_) {
      $count++;
      my $d1 = $value - $mean;
      $mean   += $d1 / $count;
      $moment += $d1 * ( $value - $mean );

      $stddev = sqrt( $moment / $count );
    }

    return ( $mean, $stddev );
  };
}

sub mean {
  my $total = 0;
  $total += $_ foreach @_;
  my $mean = sprintf( '%.02f', $total / scalar(@_) );

  return ( $total, $mean, stddev( $mean, @_ ) );
}

sub stddev {
  my ( $mean, @samples ) = @_;

  my $total = 0;
  $total += ( $_ - $mean ) * ( $_ - $mean ) foreach @samples;
  $total /= scalar(@samples);

  return sprintf( '%.02f', sqrt($total) );
}

sub variables {
  my ( $dbh, $like ) = @_;

  my $implementation = $dbh->get_info(17);
  if ( $implementation eq 'MySQL' ) {

    my $query = 'show variables';
    my $param = undef;

    if ( defined($like) ) {
      $query .= ' like ?' if ( defined($like) );
      $param = ["\%$like\%"];
    }

    my %variables;
    query(
      $dbh, $query,
      sub {
        $variables{ $_[0] } = $_[1];
      },
      $param
    );
    printObject( \%variables );
  } else {
    print("Variables not implemented for [$implementation]\n");
  }

}

sub wrapper {
  my ( $subroutine, $before_ref, $after_ref ) = @_;

  no strict 'refs';
  my $caller = ( caller() )[0];
  my $symbol
      = ( $subroutine =~ /::/ ? $subroutine : "$caller\::$subroutine" );
  my $orig = *{$symbol}{CODE};
  *{$symbol} = sub {

    $before_ref->(@_) if ( defined($before_ref) );
    my $rv = wantarray ? [ $orig->(@_) ] : $orig->(@_);
    $after_ref->($rv) if ( defined($after_ref) );

    return wantarray ? @{$rv} : $rv;
  };
}

sub quick {
  push( @_, $_ ) unless (@_);

  my $autoflush = $|;
  $| = 1;
  print( "[", join( "][", map { yellow($_) } @_ ), "]\n" );
  $| = $autoflush;
}

sub walker {
  my ( $here, $doFile, $doDir, $deep ) = @_;

  $doFile->( $here, $deep ) if ( -f $here );

  if ( -d $here ) {
    $doDir->( $here, $deep );

    opendir( my $dh, $here )
        or die("Unable to opend dir [$here] =: [$!]\n");
    my @kids = grep { !/^\.+$/o } readdir($dh);
    close($dh);

    foreach my $child (@kids) {
      walker( "$here/$child", $doFile, $doDir, $deep + 1 );
    }
  }
}

sub compareHash {
  my ( $observed, $actual ) = @_;

  my %obs = %{$observed};
  my %act = %{$actual};

  my $o_cnt = scalar( keys %obs );
  my $a_cnt = scalar( keys %act );

  message( "Sizes Differ", "  Observed := $o_cnt", "  Actual   := $a_cnt" )
      if ( $o_cnt != $a_cnt );

  foreach my $key ( keys %act ) {
    if ( exists( $obs{$key} ) ) {
      my $a_val = $act{$key};
      my $o_val = $obs{$key};
      if ( $a_val ne $o_val ) {
        message(
          "[$key] values differ:",
          "  Observed := [$o_val]",
          "  Actual   := [$a_val]"
        );
      }
      delete( $obs{$key} );
      delete( $act{$key} );
    }
  }

  message( "Values only in Observed:", map {"  [$_]"} sort keys %obs )
      if ( scalar( keys %obs ) );

  message( "Values only in Actual:", map {"  [$_]"} sort keys %act )
      if ( scalar( keys %act ) );

}

sub compareArray {
}

sub message {
  my $tmstmp = "====> " . scalar( localtime(time) );
  print( "\n", join( "\n", $tmstmp, @_ ), "\n" );
}

sub message_alert {
  my $tmstmp = "====> " . scalar( localtime(time) );
  print( "\n", join( "\n", $tmstmp, map { green($_) } @_ ), "\n" );
}

sub message_err {
  my $tmstmp = "====> " . scalar( localtime(time) );
  print( "\n", join( "\n", $tmstmp, map { red($_) } @_ ), "\n" );
}

sub query {
  my ( $dbh, $sql, $cmd, $parms ) = @_;

  my $stmt = $dbh->prepare($sql);

  if ( ref($parms) ) {
    $stmt->execute( @{$parms} );
  } else {
    $stmt->execute();
  }

  message( $stmt->errstr() ) if ( $stmt->errstr() );

  return unless ( $stmt->{Active} );

  my @results = @{ $stmt->{NAME} };
  my @tobind  = map { \$_ } @results;
  $stmt->bind_columns(@tobind);

  my @retval = undef;
  if ($cmd) {
    while ( $stmt->fetch() ) {
      $cmd->(@results);
    }
  }
  $stmt->finish();
}

sub startlog {
  local @ARGV = @_;

  my $args = { logdir => 'log' };
  GetOptions( $args, 'logdir=s', 'prefix:s', 'nolog:s' );

  my $timestr = POSIX::strftime( "%Y%m%d%H%M%S", localtime(time) );

  my $logdir;
  if ( $args->{logdir} =~ /^\/.*/o ) {
    $logdir = $args->{logdir};
  } else {
    $logdir = dirname($0) . "/$args->{logdir}";
  }

  mkdir($logdir) unless ( -e $logdir );

  my $logfile = "$logdir/";
  $logfile .= join( '',
    ( $args->{prefix} ? "$args->{prefix}." : "" ),
    "$timestr.", "$$.", 'log' );

  if ( exists( $args->{nolog} ) ) {
    if ( $args->{nolog} =~ /STDOUT/io ) {
      STDERR->close();
      *STDERR = IO::File->new(">$logfile")
          or die "Can't redirect stderr";
      STDERR->autoflush(1);
    } elsif ( $args->{nolog} =~ /STDERR/io ) {
      STDOUT->close();
      *STDOUT = IO::File->new(">$logfile")
          or die "Can't redirect stdout";
      STDOUT->autoflush(1);
    }
  } else {    # redirect both
    STDERR->close();
    *STDERR = IO::File->new(">$logfile")
        or die("[$!]Can't redirect stderr\n");
    STDOUT->close();
    *STDOUT = IO::File->new(">&STDERR") or die("[$!]Can't dup stderr");
    STDERR->autoflush(1);
    STDOUT->autoflush(1);
  }
}

1;
