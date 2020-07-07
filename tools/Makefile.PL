use ExtUtils::MakeMaker;

my @scripts = glob('bin/*');

WriteMakefile(
  NAME      => 'MiscTools',
  EXE_FILES => \@scripts,
  VERSION   => '1.' . scalar(@scripts),
);

