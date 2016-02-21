use strict;

use PSInfo;

my ($sleep, $steps, $rc) = @ARGV;

sleep($sleep);
foreach my $i (1 .. $steps){
  sleep($sleep);
	PSInfo::stepper("Step $i");
}

exit $rc;
