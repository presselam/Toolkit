use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Progress',
    VERSION_FROM      => 'lib/Progress.pm', # finds $VERSION
    PREREQ_PM         => {
        Utilities => '0.16.0',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Progress.pm', # retrieve abstract from module
       AUTHOR         => 'Andrew M. Pressel<ufotofu@whistlinglemons.com>') : ()),
);
