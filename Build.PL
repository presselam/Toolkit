use Cwd qw( cwd abs_path );
use File::Basename;
use Module::Build;

my $major   = 1;
my $minor   = 0;
my $patch   = 0;

my @jars = buildJava();
my @binaries = buildCmake();

my @scripts = glob('tools/bin/*');
push(@scripts, glob('templates/bin/*'));
push(@scripts, glob('xml/bin/*'));
push(@scripts, glob('lazy-aws/bin/*'));
push(@scripts, @binaries);

my $build = Module::Build->new(
  module_name  => 'Development Toolkit',
  dist_author => 'me',
  dist_version => "$major.$minor.$patch",
  dist_abstract => 'stuff',

  jars_files => { map{ $_ => 'jars/' . basename($_) } @jars}, 
  tmpl_files => { map{ $_ => 'tmpl/' . basename($_) } glob('templates/tmpl/*')},
  script_files => [@scripts],
  pm_files => {
    'StructurePrinter/lib/StructurePrinter.pm' => 'lib/StructurePrinter.pm',
    'jre-perl/lib/Java.pm'                     => 'lib/Java.pm',
    'Progress/lib/Progress.pm'                 => 'lib/Progress.pm',
    'PSInfo/lib/PSInfo.pm'                     => 'lib/PSInfo.pm',
    'Utilities/lib/Utilities.pm'               => 'lib/Utilities.pm',
    'Profiler/lib/Profiler.pm'                 => 'lib/Profiler.pm',
    'Toolkit/lib/Toolkit.pm'                   => 'lib/Toolkit.pm',
    'Arbeiter/lib/Arbeiter.pm'                 => 'lib/Arbeiter.pm',
  },
  py_files => {
    'python/lib/structureprinter.py' => 'py/structureprinter.py',
    'python/lib/toolkit.py'          => 'py/toolkit.py',
    'python/lib/utilities.py'        => 'py/utilities.py',
  }
);

my $install = $build->prefix() || $build->install_base() || $ENV{'HOME'};
$build->add_build_element('jars');
$build->install_path('jars' => "$install/lib/java");

$build->add_build_element('tmpl');
$build->install_path('tmpl' => "$install/.templates");

$build->add_build_element('py');
$build->install_path('py' => "$install/lib/python");

$build->create_build_script();

sub buildJava{
  my @retval;

  my $cwd = abs_path(cwd());
  foreach my $util (qw{ java }){
    chdir("$cwd/$util");
    system('mvn','clean','install');
    push(@retval, map{ "$util/$_" } glob('target/*.jar'));
  }
  chdir($cwd);

  return wantarray ? @retval : \@retval;
}

sub buildCmake {
  my @retval;

  my $cwd = abs_path(cwd());
  foreach my $util (qw{ prompt }){
    chdir("$cwd/$util");
    system('cmake', '.');
    system('make');
    push(@retval, map{ "$util/$_" } glob('bin/*'));
  }
  chdir($cwd);

  return wantarray ? @retval : \@retval;
}
