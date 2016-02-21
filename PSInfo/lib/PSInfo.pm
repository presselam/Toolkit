package PSInfo;

use strict;
use Cwd qw( abs_path );
use base qw( Exporter );
use IO::Handle;

our $VERSION = 0.9;

END { endpgm() }

my $starttime = undef;
my $cmdline   = undef;
my $args      = undef;
my @steps;

sub import {
  $starttime = time         unless($starttime);
  $cmdline   = abs_path($0) unless($cmdline);
  $args = join(' ', @ARGV) unless($args);
}

sub stepper {
  my ($label) = @_;
  push(@steps, {$label => [time, _getCoreUsage()]});
}

sub endpgm {
  my $endtime = time;

  my @lines = (
    '=' x 80,
    '====> ' . scalar localtime(),
    "Path:       $cmdline",
    "Args:       $args",
    "Run Time:   " . _convertSeconds($endtime - $starttime),
    "Core Usge:  " . _commify(_getCoreUsage()),
  );

  push(@lines, "RetCode:    $?") if( $? );

  my $lasttime = $starttime;
  if(scalar(@steps)) {
    push(@lines, "Steps:      " . scalar(@steps));
    foreach my $s (@steps) {
      foreach my $label (keys %{$s}) {
        my ($timestamp, $core) = @{$s->{$label}};
        push(
          @lines,
          "\t"
            . join(
            "\t",
            "$label:", _convertSeconds($timestamp - $lasttime),
            _commify($core)
            )
        );
        $lasttime = $timestamp;
      }
    }
  }

  push(
    @lines,
    "          =============  END OF PROCESS  =============",
    '=' x 80
  );

  print(join("\n", @lines), "\n");
}

sub _getCoreUsage {
  my $size = 0;
  if( -f "/proc/$$/statm") {
  open(my $fh, '<', "/proc/$$/statm");
  my ($sz, $rss, $share, $trs, $drs, $lrs, $dt) = split(/\s+/, <$fh>);
  $size = $sz;
  $fh->close();
  }

  return $size * 4096;
}

sub _convertSeconds {
  my ($seconds) = @_;

  my $hours = int($seconds / 3600);
  $seconds = $seconds % 3600;    # remove the hours

  my $minutes = int($seconds / 60);
  $seconds = $seconds % 60;      # remove the minutes

  return sprintf("%02d:%02d:%02d", $hours, $minutes, $seconds);
}

sub _commify {
  my ($val) = @_;
  1 while($val =~ s/^(-?\d+)(\d{3})/$1,$2/);
  return $val;
}
1;
