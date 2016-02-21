use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  'NAME'         => 'Profiler',
  'VERSION_FROM' => 'lib/Profiler.pm',    # finds $VERSION
  'PREREQ_PM'    => {},                   # e.g., Module::Name => 1.1
);
