package Utilities;

use strict;
use base qw( Exporter );
use File::Basename;
use Getopt::Long;
use IO::File;
use POSIX qw( strftime );
use Term::ANSIColor qw( :constants );

use StructurePrinter;

our @EXPORT_OK =
  qw( dump_table quick startlog query message walker compareThingy compareArray compareHash wrapper variables mean stddev printStats convertSeconds red green yellow blue magenta white reload_module backspace );

our %EXPORT_TAGS = (
  COMPARE => [qw( compareThingy compareHash compareArray )],
  LOG     => [qw( startlog )],
  MISC    => [qw( quick message walker wrapper reload_module backspace)],
  SQL     => [qw( query variables )],
  STATS   => [qw( mean stddev )],
  TIME    => [qw( convertSeconds )],
  COLOR   => [qw( red green yellow blue magenta white )],
  ALL     => [@EXPORT_OK],
);

our $VERSION = '0.16.0';

our %MTIME;

sub dump_table {
  my %args = @_;

  my @table = @{$args{'table'}};

  my @widths;
  foreach my $ref (@table) {
    foreach my $i (0 .. scalar(@{$ref})) {
      $widths[$i] = length($ref->[$i])
        if(length($ref->[$i]) > $widths[$i]);
    }
  }

  my $hdr = '+-' . join('-+-', map { '-' x $_ } @widths) . '-+';
  my $fmt = join('', map { "| %" .$_ . "s " } @widths);

  print("$hdr\n");
  printf("$fmt|\n", @{shift @table});
  print("$hdr\n");

  if(exists($args{'sort'})) {
    @table = sort {
      $a->[$args{'sort'}] <=> $b->[$args{'sort'}]
        || $a->[$args{'sort'}] cmp $b->[$args{'sort'}]
    } @table;
  }

  printf("$fmt|\n", @{$_}) foreach @table;
  print("$hdr\n");
}

sub backspace {
  my ($orig) = @_;

  my @tmp = unpack("C*", reverse($orig));
  my $del = 0;
  my @new;

  foreach my $char (@tmp) {
    if(($char == 127) || ($char == 8)) {
      $del++;
      next;
    } elsif ($del != 0) {
      $del--;
      next;
    } else {
      push(@new, $char);
    }
  }

  return pack("C*", reverse(@new));
}

sub reload_module {
  my ($module) = @_;
  $module =~ s/\:\:/\//go;
  $module .= '.pm';

  return unless(exists($INC{$module}));

  my $file  = $INC{$module};
  my $mtime = (stat $file)[9];
  $MTIME{$file} = $^T unless(exists($MTIME{$file}));

  if($mtime > $MTIME{$file}) {
    delete($INC{$module});
    require($module);
    $MTIME{$file} = $mtime;
  }
}

sub red {
  my ($str, $format) = @_;
  return RED . $str . RESET;
}

sub green {
  my ($str, $format) = @_;
  return GREEN . $str . RESET;
}

sub yellow {
  my ($str, $format) = @_;
  return YELLOW . $str . RESET;
}

sub blue {
  my ($str, $format) = @_;
  return BLUE . $str . RESET;
}

sub magenta {
  my ($str, $format) = @_;
  return MAGENTA . $str . RESET;
}

sub white {
  my ($str, $format) = @_;
  return WHITE . $str . RESET;
}

sub convertSeconds {
  my ($seconds) = @_;

  my $hours = int($seconds / 3600);
  $seconds = $seconds % 3600;    # remove the hours

  my $minutes = int($seconds / 60);
  $seconds = $seconds % 60;      # remove the minutes

  return sprintf("%02d:%02d:%02d", $hours, $minutes, $seconds);
}

sub mean {
  my $total = 0;
  $total += $_ foreach @_;
  my $mean = sprintf('%.02f', $total / scalar(@_));

  return ($total, $mean, stddev($mean, @_));
}

sub stddev {
  my ($mean, @samples) = @_;

  my $total = 0;
  $total += ($_ - $mean) * ($_ - $mean) foreach @samples;
  $total /= scalar(@samples);

  return sprintf('%.02f', sqrt($total));
}

sub variables {
  my ($dbh, $like) = @_;

  my $implementation = $dbh->get_info(17);
  if($implementation eq 'MySQL') {

    my $query = 'show variables';
    my $param = undef;

    if(defined($like)) {
      $query .= ' like ?' if(defined($like));
      $param = ["\%$like\%"];
    }

    my %variables;
    query(
      $dbh, $query,
      sub {
        $variables{$_[0]} = $_[1];
      },
      $param
    );
    printObject(\%variables);
  } else {
    print("Variables not implemented for [$implementation]\n");
  }

}

sub wrapper {
  my ($subroutine, $before_ref, $after_ref) = @_;

  no strict 'refs';
  my $caller = (caller())[0];
  my $symbol =
    ($subroutine =~ /::/ ? $subroutine : "$caller\::$subroutine");
  my $orig = *{$symbol}{CODE};
  *{$symbol} = sub {

    $before_ref->(@_) if(defined($before_ref));
    my $rv = wantarray ? [$orig->(@_)] : $orig->(@_);
    $after_ref->($rv) if(defined($after_ref));

    return wantarray ? @{$rv} : $rv;
  };
}

sub quick {
  my $autoflush = $|;
  $| = 1;
  print("[", join("][", map { yellow($_) } @_), "]\n");
  $| = $autoflush;
}

sub walker {
  my ($here, $doFile, $doDir, $deep) = @_;

  $doFile->($here, $deep) if(-f $here);

  if(-d $here) {
    $doDir->($here, $deep);

    opendir(my $dh, $here)
      or die("Unable to opend dir [$here] =: [$!]\n");
    my @kids = grep { !/^\.+$/o } readdir($dh);
    close($dh);

    foreach my $child (@kids) {
      walker("$here/$child", $doFile, $doDir, $deep + 1);
    }
  }
}

sub compareHash {
  my ($observed, $actual) = @_;

  my %obs = %{$observed};
  my %act = %{$actual};

  my $o_cnt = scalar(keys %obs);
  my $a_cnt = scalar(keys %act);

  message("Sizes Differ", "  Observed := $o_cnt", "  Actual   := $a_cnt")
    if($o_cnt != $a_cnt);

  foreach my $key (keys %act) {
    if(exists($obs{$key})) {
      my $a_val = $act{$key};
      my $o_val = $obs{$key};
      if($a_val ne $o_val) {
        message(
          "[$key] values differ:", "  Observed := [$o_val]",
          "  Actual   := [$a_val]"
        );
      }
      delete($obs{$key});
      delete($act{$key});
    }
  }

  message("Values only in Observed:", map { "  [$_]" } sort keys %obs)
    if(scalar(keys %obs));

  message("Values only in Actual:", map { "  [$_]" } sort keys %act)
    if(scalar(keys %act));

}

sub compareArray {
}

sub message {
  my $tmstmp = "====> " . scalar(localtime(time));
  print("\n", join("\n", $tmstmp, @_), "\n");
}

sub query {
  my ($dbh, $sql, $cmd, $parms) = @_;

  my $stmt = $dbh->prepare($sql);

  if(ref($parms)) {
    $stmt->execute(@{$parms});
  } else {
    $stmt->execute();
  }

  message($stmt->errstr()) if($stmt->errstr());

  return unless($stmt->{Active});

  my @results = @{$stmt->{NAME}};
  my @tobind = map { \$_ } @results;
  $stmt->bind_columns(@tobind);

  my @retval = undef;
  if($cmd) {
    while($stmt->fetch()) {
      $cmd->(@results);
    }
  }
  $stmt->finish();
}

sub startlog {
  local @ARGV = @_;

  my $args = {logdir => 'log'};
  GetOptions($args, 'logdir=s', 'prefix:s', 'nolog:s');

  my $timestr = POSIX::strftime("%Y%m%d%H%M%S", localtime(time));

  my $logdir;
  if($args->{logdir} =~ /^\/.*/o) {
    $logdir = $args->{logdir};
  } else {
    $logdir = dirname($0) . "/$args->{logdir}";
  }

  mkdir($logdir) unless(-e $logdir);

  my $logfile = "$logdir/";
  $logfile .= join(
    '', ($args->{prefix} ? "$args->{prefix}." : ""), "$timestr.",
    "$$.", 'log'
  );

  if(exists($args->{nolog})) {
    if($args->{nolog} =~ /STDOUT/io) {
      STDERR->close();
      *STDERR = IO::File->new(">$logfile")
        or die "Can't redirect stderr";
      STDERR->autoflush(1);
    } elsif ($args->{nolog} =~ /STDERR/io) {
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
