use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  'NAME'         => 'Toolkit',
  'VERSION_FROM' => 'lib/Toolkit.pm',    # finds $VERSION
  'PREREQ_PM'    => {
    Profiler => 1.0,
    PSInfo   => 0.9,
    StructurePrinter => 0.9,
    Utilities => 0.16,
  },                       # e.g., Module::Name => 1.1
);
