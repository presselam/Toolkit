package MDS::Java;

#==============================================================
# This class defines the running environment of a Java program.
# At the heart of this class is a methodology for building the
# classpath and for passing arguments to the Java program.
#
# As a best-practice arguments are passed only as properties.
#
#     -jre version
#          takes the version of the jre that is to be used.
#          This allows the current default to be changed.
#
#     -encoding enc
#          sets the output file encoding property (file.encoding)
#          for the jre.
#          The default is UTF8. Common value is ISO8859-1.
#
#     -xml [version]
#          takes an optional argument of the version of the
#          xerces parser that is to be used. If there is no
#          argument then it uses the current default.
#          Note: the Apache Crimson parser is built into
#          java 1.4. Use this flag for performance gains.
#
#     -xsl [version]
#          takes an optional argument of the version of the
#          xalan parser that is to be used. If there is no
#          argument then it uses the current default.
#          Note: xalan is built into java 1.4 but it is an
#          early version. Use this flag to specify a more
#          recent version.
#
#     -jpkg jarfile
#           takes either a full path to a jar file or a relative
#           path to a jar file. If the path is relative it is
#           to be found in $ENV{LIBDIR}, $ENV{MDS_LIBDIR}/java
#           or in the company standard location.
#
#     -mx size
#           specifies the maximum heap size in meg
#
#     -ms size
#           specifies the minimum heap size in meg
#
#     -jdbcsyb [version]
#           specifies that a jdbc sybase driver is to be supplied
#           If the argument is not present then use the default.
#
#     -jdbcora [version]
#           specifies that a jdbc oracle driver is to be supplied
#           If the argument is not present then use the default.
#
#     -jprop name=value
#           Specifies a property for the application
#           These are written to main.properties in the current
#           working directory.
#
#     -jdef name=value
#           Specifies a property for the jre.
#           These are added as -Dname=value to the execution
#           of the jre.
#
#     -jmain class
#           specifies the path of the class whose main is to
#           be run
#
#     -jfile filename
#           specifies the file that -jprop values are to be
#           written. Defaults to main.properties.
#
#     -jflag name=value
#           specifieds a command line argument to the java
#           program. This will add it to the command line
#           in the form "-name value".  The '=' will be
#           removed.
#
# Definition of classpath:
# The variable CLASSPATH is not defined. -classpath is used
# instead.
# If the environment variable INPUTDIR is defined, it is added
# to the classpath.
#==============================================================
require 5.006;

use strict;
use File::Basename;
use File::Copy;
use File::Temp qw( tempdir );
use MDS::Utilities;

# This allows a program to change the default for all
# Example $MDS::Java::DEFAULT_JRE="1.5";
use vars qw($DEFAULT_JRE
	      $DEFAULT_ENCODING
	      $DEFAULT_VERSION
	      $OFFICIAL_JAVA_ROOT
	      $OFFICIAL_JAVA_PKGS
	      $DEFAULT_MIN_HEAP
	      $DEFAULT_MAX_HEAP
	      $DEFAULT_XML
	      $DEFAULT_XSL
	      $DEFAULT_PROPERTY_FILE );

# The company's offical location of java and its packages
$DEFAULT_JRE           = "1.4.2";
$DEFAULT_ENCODING      = "UTF8";
$DEFAULT_VERSION       = 1.4;	# version as a major.minor decimal number 1.4.0_p3
				# would be 1.4
$OFFICIAL_JAVA_ROOT    = "/usr/local/java";
$OFFICIAL_JAVA_PKGS    = "$OFFICIAL_JAVA_ROOT/pkgs";
$DEFAULT_MIN_HEAP      = 0;	# use java's default
$DEFAULT_MAX_HEAP      = 1500;	# 1.5G
$DEFAULT_XML           = "2.2.1";
$DEFAULT_XSL           = "2.4.1";
$DEFAULT_PROPERTY_FILE = "main.properties";

my @env_map = qw(
         MDT_DB_LEVEL
         SSDF_DB_LEVEL
         GFFT_DB_LEVEL
         SMI_DB_LEVEL

         APPDIR
         BINDIR
         DATADIR
         INPUTDIR
         LIBDIR
         LOGDIR
         STATUSDIR
         PWD

         MDS_DOMAIN
         MDS_FAMILY
         MDS_START
         MDS_ADMIN
         RUN_LEVEL

         MDS_ROOT
         DM_ROOTDIR
         GFFT_ROOTDIR
         MDT_ROOTDIR
         MCM_ROOTDIR
         SMI_ROOTDIR
         SSDF_ROOTDIR
         );

sub new {
    my ($class, @info) = @_;
    $class = ref($class) || $class;
    my $self = bless {
			jre		=> $DEFAULT_JRE,
			encoding	=> $DEFAULT_ENCODING,
			version		=> $DEFAULT_VERSION,
			ms		=> $DEFAULT_MIN_HEAP,
			mx		=> $DEFAULT_MAX_HEAP,
			jfile		=> $DEFAULT_PROPERTY_FILE,
			# map all args that can take an optional argument to squat
			# or we won't know what was called without the optional arg
			jdbcora		=> 'squat',
			jdbcsyb		=> 'squat',
			xml		=> 'squat',
			xsl		=> 'squat',
			gc		=> 0,
			jdir		=> [ $ENV{ LIBDIR }, $ENV{ JAVADIR } ],
			classpath		=> [ '.' ],
    }, $class;
    $self->init(@info);
    return $self;
}

sub init{
    my ($self, @parms) = @_;

	# We want to use the contents of ARGV,
	# but for it to remain unchanged by this routine,
	# However GetOptions only reads ARGV and modifies it.
	# Therefore we append ARGV onto parms
	# and then make ARGV a local copy of parms
    push(@parms, @ARGV);
    local @ARGV = @parms;

    use Getopt::Long;
    $Getopt::Long::passthrough=1; # ignore unknown flags
    #$Getopt::Long::debug=1;
    GetOptions(  $self,
		  "encoding=s",
		  "jre=s",
		  "jdbcsyb:s",
		  "jdbcora:s",
		  "jprop=s@",
		  "jdef=s@",
		  "jdir=s@",
		  "jpkg=s@",
		  "ms=i",
		  "mx=i",
		  "xml:s",
		  "xsl:s",
		  "jmain=s",
		  "jfile=s",
		  "jflag=s@",
		  "jargs=s@",
		  "xx=s@",
		  "gc!",
		  "client!",
		  "server!",
            );
    $Getopt::Long::passthrough=0; # Restore default behavior
    #$Getopt::Long::debug=0;

    # delete all keys that were not passed by the program
    foreach my $arg (keys %$self) {
	delete $self->{$arg} if ($self->{$arg} eq "squat");
    }

    if (!exists($self->{jdbcsyb})) { # not passed
	$self->{jdbcsyb} = "0";
    } elsif (!$self->{jdbcsyb}) { # passed w/o argument
	$self->{jdbcsyb} = "1";
    }

    if (!exists($self->{jdbcora})) { # not passed
	$self->{jdbcora} = "0";
    } elsif (!$self->{jdbcora}) { # passed w/o argument
	$self->{jdbcora} = "1";
    }

    if (!exists($self->{xml})) { # not passed
	$self->{xml} = "0";
    } elsif (!$self->{xml}) { # passed w/o argument
	$self->{xml} = "1";
    }

    if (!exists($self->{xsl})) { # not passed
	$self->{xsl} = "0";
    } elsif (!$self->{xsl}) { # passed w/o argument
	$self->{xsl} = "1";
    }

    $self->oraJdbcEnv();
    $self->xmlEnv();
    $self->xslEnv();
    $self->jarEnv();
    $self->javaEnv();
    $self->cmdEnv();
    $self->mapEnv();
}

# add Oracle driver to classpath
sub oraJdbcEnv {
    my ($self) = @_;

    # if ora_jdbc is zero then the flag was not passed.
    return if (!exists($self->{jdbcora}));

    MDS::Env::oraEnv();

    # flag was passed with no argument
    # set the default
    my $ora_jdbc = $self->{jdbcora};
    $ora_jdbc = "classes12.zip" if ($ora_jdbc eq "1");

    push(@{$self->{classpath}}, "$ENV{ORACLE_HOME}/jdbc/lib/$ora_jdbc")
			if (-f "$ENV{ORACLE_HOME}/jdbc/lib/$ora_jdbc");
}

# Establish the jre
sub javaEnv {
    my ($self) = @_;
    $self->{home} = "$OFFICIAL_JAVA_ROOT/jre$self->{jre}";
    $self->{version} = substr($self->{jre}, 0, 3);
}

# Add xml to the running of the program
sub xmlEnv {
    my ($self) = @_;

    # if xml is zero then the flag was not passed.
    my $xml = $self->{xml};
    if ($xml ne "0") {
	$xml = "2.2.1" if ($xml eq "1"); # use the default
	if (-f "$OFFICIAL_JAVA_PKGS/xerces$xml/xercesImpl.jar") {
	    if ($self->{version} >= 1.4) {
		# java 1.4 has to use -Djava.endorsed.dirs to locate xerces and
		# xalan otherwise it uses its own internal copy
		push(@{$self->{endorse}}, "$OFFICIAL_JAVA_PKGS/xerces$xml");
		# bind its factories
		push(@{$self->{java_args}}
		     , "-Djavax.xml.parsers.DocumentBuilderFactory="
		     . "org.apache.xerces.jaxp.DocumentBuilderFactoryImpl"
		     , "-Djavax.xml.parsers.SAXParserFactory="
		     . "org.apache.xerces.jaxp.SAXParserFactoryImpl");
	    }
	    $xml= "$OFFICIAL_JAVA_PKGS/xerces$xml/xercesImpl.jar:"
		    . "$OFFICIAL_JAVA_PKGS/xerces$xml/xmlParserAPIs.jar";
	} else {
	    $xml="$OFFICIAL_JAVA_PKGS/xerces$xml/xerces.jar";
	}
	push(@{$self->{classpath}}, $xml);
    }
}

# Add xsl to the running of the program
sub xslEnv {
    my ($self) = @_;

    # if xsl is zero then the flag was not passed.
    my $xsl = $self->{xsl};
    if ($xsl ne "0") {
	$xsl = "2.4.1" if ($xsl eq "1"); # use the default
	if ($self->{version} >= 1.4) {
	    # java 1.4 has to use -Djava.endorsed.dirs to locate xerces and
	    # xalan otherwise it uses its own internal copy
	    push(@{$self->{endorse}}, "$OFFICIAL_JAVA_PKGS/xalan$xsl");
	    # bind its factory
	    push(@{$self->{java_args}}
		    , "-Djavax.xml.transform.TransformerFactory="
		    . "org.apache.xalan.processor.TransformerFactoryImpl" );
	}
    push(@{$self->{classpath}}, "$OFFICIAL_JAVA_PKGS/xalan$xsl/xalan.jar");
    }
}

# Add jars and folders to the classpath
sub jarEnv {
    my ($self) = @_;

    $self->{ tmpdir } = tempdir(
				    'java.XXXX',
				    CLEANUP	=> 1,
				    DIR		=> $ENV{ APPDIR }
			    );
    my $tmp = $self->{ tmpdir };

    my @missing;
    foreach my $pkg (@{$self->{jpkg}}) {
	if ( -d $pkg ) {
	    push(@{$self->{classpath}}, $pkg);
	} elsif ( -f $pkg ) {
	    copy( $pkg, $tmp );
	    my $file = basename( $pkg );
	    push(@{$self->{classpath}}, "$tmp/$file" );
	} else {
	    # look in the standard locations for the file
	    my $found = 0;
	    foreach my $dir ( @{ $self->{ jdir } }, "$ENV{MDS_LIBDIR}/java",
			    "$ENV{MDT_ROOTDIR}/common/java", $OFFICIAL_JAVA_PKGS) {
		if (-f "$dir/$pkg") {
		    copy( "$dir/$pkg", $tmp );
		    my $filename = basename( $pkg );
		    push(@{$self->{classpath}}, "$tmp/$filename");
		    $found++;
		    last;
		}
	    }
	    push(@missing, $pkg) unless( $found );
	}
    }
    check_retcode("Missing Package", scalar(@missing), join(",", @missing));
}

# add parameters to the java command
sub cmdEnv{
    my ($self) = @_;
    # create JAVA_ARGS
    if ($self->{endorse} && @{$self->{endorse}}) {
	push(@{$self->{java_args}}, "-Djava.endorsed.dirs=" .
				    join(":", @{$self->{endorse}}));
    }
    push(@{$self->{java_args}}, "-ms$self->{ms}m")  if ($self->{ms});
    push(@{$self->{java_args}}, "-mx$self->{mx}m")  if ($self->{mx});
    push(@{$self->{java_args}}, "-verbose:gc")      if ($self->{gc});
    push(@{$self->{java_args}}, "-server")          if ($self->{server});
    push(@{$self->{java_args}}, "-client")          if ($self->{client});

    # add in the non standard, jvm specific arguments
    push(@{$self->{java_args}}, map { "-XX:$_" } @{$self->{xx}})
	    if ($self->{xx} && @{$self->{xx}});

    # add in the leading - to all values in java_args
    push(@{$self->{java_args}}, map { "-D$_" } @{$self->{jdef}})
	    if ($self->{jdef} && @{$self->{jdef}});

    # explicitly set the output file encoding.
    push(@{$self->{java_args}}, "-Dfile.encoding=$self->{encoding}");

    # create CLASSPATH
    push(@{$self->{classpath}}, $ENV{INPUTDIR})  if (exists($ENV{INPUTDIR}));
}

# map environment variables to java properties
# These go into $self->{jfile} unless it's value is dont.
# In which case they are -Dname=value args to Java
sub mapEnv {
    my ($self) = @_;

    # add in the leading - to all values in java_args
    my $fh = undef;
    if (exists($self->{jfile}) && $self->{jfile} !~ /^dont$/io) {
	$fh = IO::File->new(">$self->{jfile}");
    }
    if ($fh) {
	push(@{$self->{java_args}}, "-Dmain.properties=$self->{jfile}")
		if ($self->{jfile} ne $DEFAULT_PROPERTY_FILE);
	$fh->print(join("\n", @{$self->{jprop}}), "\n")
		if ($self->{jprop} && @{$self->{jprop}});
	foreach my $var (@env_map) {
	    if (defined($ENV{$var})) {
		my $property = lc($var);
		$property =~ s/_/./go;
		$fh->print("$property=$ENV{$var}\n");
	    }
	}
    } else {
	push(@{$self->{java_args}}, map { "-D$_" } @{$self->{jprop}})
		if ($self->{jprop} && @{$self->{jprop}});
	foreach my $var (@env_map) {
	    if (defined($ENV{$var})) {
		my $property = lc($var);
		$property =~ s/_/./go;
		push(@{$self->{java_args}}, "-D$property=$ENV{$var}");
	    }
	}
    }
}

# return 0 on success, exit code otherwise
sub run {
    my ($self) = @_;
    my @args = ("$self->{home}/bin/java",
              "-classpath",
              join(":", @{$self->{classpath}}),
              @{$self->{java_args}},
              $self->{jmain}
            );

    push(@args, map { split(/=/, $_); } @{$self->{jflag}})
	if ($self->{jflag} && @{$self->{jflag}});

    push(@args, @{$self->{jargs}}) if ($self->{jargs} && @{$self->{jargs}});

    STDERR->print("[", join("][", @args), "]\n\n");

    my $retcode = system(@args);

    if ($retcode != 0) {
	my $exit_value  = $? >> 8;
	return $exit_value;
    }
  return 0;
}

sub dump {
    my( $self ) = @_;
    use Data::Dumper;
    my $d = Data::Dumper->new( [ $self ], [ qw( Java ) ] );
    print "\n", $d->Dump(), "\n";

    my @args = ("$self->{home}/bin/java",
              "-classpath",
              join(":", @{$self->{classpath}}),
              @{$self->{java_args}},
              $self->{jmain}
            );

    push(@args, map { split(/=/, $_); } @{$self->{jflag}})
	if ($self->{jflag} && @{$self->{jflag}});

    push(@args, @{$self->{jargs}}) if ($self->{jargs} && @{$self->{jargs}});

    STDERR->print("[", join("][", @args), "]\n\n");
}


1;
