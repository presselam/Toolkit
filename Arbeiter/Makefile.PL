use 5.010000;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Arbeiter',
    VERSION_FROM      => 'lib/Arbeiter.pm', # finds $VERSION
    PREREQ_PM         => {
        Paws => '0.46',
        Utilities => '0.28.0',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Arbeiter.pm', # retrieve abstract from module
       AUTHOR         => 'Andrew M. Pressel<ufotofu@whistlinglemons.com>') : ()),
);
