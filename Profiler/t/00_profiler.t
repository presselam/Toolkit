use strict;
use Test::More;
plan tests => 18;

use Profiler;

benchmark('dummy_sub');
benchmark('ret_scalar');
benchmark('ret_list');
benchmark('ret_hash');

my $rv = ret_scalar();
is($rv, 'a', 'Scalar Scalar');
my @rv = ret_scalar();
is($rv[0], 'a', 'Scalar List');

$rv = ret_list();
is($rv, 26, 'List Scalar');
@rv = ret_list();
is($rv[25], 'z', 'List List');

$rv = ret_hash();
is($rv->{m}, 109, 'Hash Scalar');
my %rv = ret_hash();
is($rv{q}, 113, 'Hash List');

foreach my $i (0 .. 5){
  test_timing($i);
}

sub test_timing {
  my $capture;
  open(my $fh, '>', \$capture) or die("cant create capture\n");

  my $keep = \*STDERR;
	*STDERR = $fh;

  dummy_sub($_[0]);
	close($fh);

	chomp($capture);
	
	my ($func, $hr, $min, $sec, $ms) =
	  $capture =~ /\[(.*)\] completed in ([0-9]+h )?([0-9]+m )?([0-9]+s )?([0-9]+ms)/io;
		print("[$capture]\n");

  s/[ hms]//go foreach grep{ defined($_) } $hr, $min, $sec, $ms; 
	$sec = 0 unless( defined($sec) );


	is($func, 'dummy_sub', 'Wrapper Test');
	is($sec, $_[0], 'Timing Test');

  *STDERR = $keep;
}

sub dummy_sub {
  sleep($_[0]);
}

sub ret_scalar {
  my $rv = 'a';
  return $rv;
}

sub ret_list {
  my @rv = 'a' .. 'z';
  return @rv;
}

sub ret_hash {
  my %rv = map { $_ => ord($_) } 'a' .. 'z';

  wantarray ? %rv : \%rv;
}

