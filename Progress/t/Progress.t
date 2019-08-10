# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Progress.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 13;
BEGIN { use_ok('Progress') }

my $howmany = 100;
my $howoften = 50;
chomp(my @time = <DATA>);

my $prog = Progress->new(how_many => $howmany);
foreach (1 .. $howmany){
  $prog->tick();
}

is($prog->{'how_often'}, 10, 'How often should it print stats');
is($prog->{'how_many'}, 100, 'How many expected thingies');
is(scalar(@{$prog->{'TIMESTAMPS'}}), 101, 'Tick Count');
is($prog->{'marker'}, ($prog->{'how_often'} + $prog->{'how_many'}), 'Marker Count');

$prog =  Progress->new(how_many => $howmany, how_often => $howoften);
is($prog->{'how_often'}, $howoften, 'How often should it print stats');
$prog->tick(record => $_) foreach (1 .. $howmany);

$prog->{'how_many'} = 300;
$prog->{'TIMESTAMPS'} = \@time; # Create Repeatable Times Tests
my $stat = $prog->calc_stats(Records => 12358);

is($stat->{'Completed'}, 100, 'Stat: Completed');
#is($stat->{'ETA'}, 'Sat Feb 27 17:51:31 2010', 'Stat: ETA');
is($stat->{'Elapsed'}, '14:42:06', 'Stat: Elapsed');
is($stat->{'First'}, 'Fri Feb 26 12:19:01 2010', 'Stat: First');
is($stat->{'Last'}, 'Sat Feb 27 03:01:07 2010', 'Stat: Last');
is($stat->{'Mean'}, '00:08:49', 'Stat: Mean');
is($stat->{'Records'}, 12358, 'Stat: Records');
is($stat->{'Remaining'}, 200, 'Stat: Remaining');

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
__DATA__
1267204741
1267205516
1267206045
1267206422
1267206605
1267207407
1267207956
1267208734
1267208836
1267209713
1267210096
1267210278
1267211126
1267211199
1267211898
1267212592
1267213510
1267213919
1267214411
1267214701
1267215207
1267215428
1267216392
1267216495
1267216898
1267217589
1267218573
1267219041
1267219514
1267220391
1267220835
1267220869
1267221004
1267221681
1267222254
1267223028
1267223623
1267224092
1267224693
1267225660
1267225861
1267225943
1267226472
1267227188
1267227491
1267228041
1267228992
1267229323
1267230041
1267230651
1267231407
1267231531
1267232370
1267232654
1267233195
1267233311
1267233383
1267233751
1267234687
1267235190
1267235782
1267236110
1267237065
1267237130
1267238070
1267238651
1267239109
1267239430
1267239631
1267240069
1267240903
1267241652
1267242646
1267242770
1267243604
1267244555
1267244886
1267245019
1267245945
1267246822
1267246879
1267247141
1267247764
1267248753
1267249534
1267250203
1267250703
1267251025
1267251446
1267251619
1267252089
1267252370
1267253291
1267253682
1267254248
1267254951
1267255922
1267256457
1267257156
1267257404
1267257667
