use strict;

use Test::More;

plan tests => 26;

use constant {
  PATH     => 'Path',
  ARGS     => 'Args',
  RUNTIME  => 'Run Time',
  CORE     => 'Core Usge',
  STEPS    => 'Steps',
  STEP_ONE => 'Step 1',
  RETCODE  => 'RetCode'
};

test_it(0, 0, 0);
test_it(0, 0, 5);
test_it(0, 9, 0);
test_it(3, 0, 0);
test_it(8, 2, 4);

sub test_it {
  my ($sleep, $step, $retcode) = @_;

  my @psinfo = qx{ perl -Iblib/lib t/test.pl $sleep $step $retcode };
	print @psinfo;
  chomp(@psinfo);

  foreach my $ln (@psinfo) {
    next unless($ln =~ /:\s+/o);

    my ($name, $value) = split(/:\s+/, $ln);
		$name =~ s/^\s*//o;

    if($name eq PATH) {
      like($value, '/t\/test.pl$/', PATH);
    }
    if($name eq ARGS)     {
		  is($value, join(' ', @_), ARGS);
		}
    if($name eq RUNTIME)  { 
		  like($value, '/^[0-9:]+$/', RUNTIME);
		}
    if($name eq CORE)     {
		  like($value, '/^[0-9,]+$/', CORE);
		}
    if($name eq STEPS)    {
		  is($value, $step, STEPS);
		}
    if($name eq STEP_ONE) {
		  like($value, '/^[0-9:,\t]+$/', STEP_ONE);
		}
    if($name eq RETCODE)  {
		  is($value, $retcode, RETCODE);
		}
  }
}
