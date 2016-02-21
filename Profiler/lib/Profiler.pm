package Profiler;

=head1 Name

Profiler - Easily time all the runs of subroutines

=head1 Synopsis

    use Profiler;
    benchmark('function_to_time');

    function_to_time(@arguments);

=head1 Description

Benchmarking a subroutine makes it easy to get run time statistics every time the
subroutine is run.  This is most useful during debugging when a subroutine has 
been modified and we need to know how that will impact run times.

Whenever the benchmarked subroutine completes, then this module will print out
the run time on STDERR.  Here's an example of what will be printed on SDTERR:

    [function_to_time] completed in 9s 332ms

The module uses a high resolution timer to track the runtime so it can track
your subroutine down to the milliseconds.

You could benchmark it yourself, by modifying the code, like the following:

    my $beg = time();
    function_to_time(@arguments);
    print("Completed in ", time() - $beg, " seconds\n");

But you have to find everywhere the subroutine is called and change the calling
code. Or you can, hopefully, more simply do:

    use Profiler;
    benchmark('function_to_time');

This makes it easy to turn benchmarking on and off.  

=cut

use strict;
use Time::HiRes qw( time tv_interval );

use base qw( Exporter );
our @EXPORT = qw( benchmark );

our $VERSION = 1.0;

=head1 Subrountines

=over 1

=item * benchmark("function_to_time")

This is the only subroutine that is exported. Everything else is private.

This subroutine will find the code reference to the specified subroutine,
C<function_to_time>, and create a wrapper around it that has the timing logic.
Once it has created the timing wrapper it will then install the wrapper 
under the function name.

The wrapper simply gets a timestamp, calls the original subrountine, and then
it gets the timestamp once the subroutine completes.  Then it does some simple
math on the two timestamps and prints out the result on STDERR.

This means that everytime anything calls C<function_to_time>, the wrapper is
actually called instead. The wrapper is who calls the original subroutine.

=cut

sub benchmark {
  my ($fn) = @_;

  my $package = caller(0);

  no strict qw( refs );
  my $ref = *{"$package\::$fn"}{CODE};
  die("Cannot benchmark [$fn]") unless(defined($ref));

  *{"$package\::$fn"} = sub {

    # We need to make sure the calling context is preserved when we
    # call the subroutine.

    my ($t0, $t1) = (0, 0);
    $t0 = [time()];
    my $retval = wantarray ? [$ref->(@_)] : $ref->(@_);
    $t1 = [time()];

    _timestr($fn, $t0, $t1);

    return wantarray ? @{$retval} : $retval;
  };
}

sub _timestr {
  my ($fn, $t0, $t1) = @_;

  my $diff = tv_interval($t0, $t1);
  my $ms   = int(($diff - int($diff)) * 1000);
  my $sc   = int($diff) % 60;
  my $mn   = int($diff / 60);
  my $hr   = int($diff / 3600);

  print STDERR (
    "[$fn] completed in",
    ($hr ? " $hr" . "h" : ''),
    ($mn ? " $mn" . "m" : ''),
    ($sc ? " $sc" . "s" : ''),
    " $ms" . "ms\n"
  );
}

1;

__END__

=back

=head1 Gotchas

=over 1

=item * Redundant Calls

Don't do this; It's not what you want ...

    foreach (1 .. 5){
      benchmark('doSomething');
    }  

Because you told it that when doSomething is called you wanted this...

    [doSomething] completed in 9s 322ms
    [doSomething] completed in 9s 322ms
    [doSomething] completed in 9s 322ms
    [doSomething] completed in 9s 322ms
    [doSomething] completed in 9s 323ms

Benchmark will create a wrapper for a wrapper for a wrapper for a wrapper for
a wrapper for the original subroutine.  Unless, it is what you want.

=back

=cut





