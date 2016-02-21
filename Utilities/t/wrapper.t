use strict;

use Test::More;
plan tests => 10;

use Utilities qw( wrapper );

my ($bef, $aft) = (0,0);

my $before = sub{ $bef++; };
my $after = sub{ $aft++; };

wrapper('test_sub_1', $before, $after);
test_sub_1() foreach 1 .. 5;
is($bef, 5, 'Test 1 - Before');
is($aft, 5, 'Test 1 - After');

wrapper('test_sub_2', $before);
test_sub_2() foreach 1 .. 5;
is($bef, 10, 'Test 2 - Before');
is($aft, 5, 'Test 2 - After');

wrapper('test_sub_3', undef, $after);
test_sub_3() foreach 1 .. 5;
is($bef, 10, 'Test 3 - Before');
is($aft, 10, 'Test 3 - After');

wrapper('test_sub_4');
test_sub_4() foreach 1 .. 5;
is($bef, 10, 'Test 4 - Before');
is($aft, 10, 'Test 4 - After');

wrapper('wrapper_test::test_wrapper', $before, $after);
wrapper_test::test_wrapper() foreach 1 .. 5;
is($bef, 15, 'Test 5 - Before');
is($aft, 15, 'Test 5 - After');

# Doesn't need to do anything, just needs to be callable;
sub test_sub_1{};
sub test_sub_2{};
sub test_sub_3{};
sub test_sub_4{};

package wrapper_test;

sub test_wrapper{}
