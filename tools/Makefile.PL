use ExtUtils::MakeMaker;

my @scripts = qw( unique.pl nmr );

print(%Config);

WriteMakefile(
  NAME      => 'MiscTools',
  EXE_FILES => \@scripts,
  VERSION   => '1.' . scalar(@scripts),
);
