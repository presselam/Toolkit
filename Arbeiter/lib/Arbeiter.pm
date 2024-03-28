package Arbeiter;

use strict;
use 5.020;
use base qw( Exporter );

use Cwd qw( abs_path );
use File::Basename;
use GitLab::API::v4;
use Paws;
use Paws::Credential::File;
use YAML::Tiny;
use Utilities qw( message );

our $VERSION = '0.1.0';

our @EXPORT
    = qw( CreateGitlabClient CreateAwsClient CurrentService GetServices GetConfiguration GetWorkList );

my $CONF;
my %SERVICES;
my $CLIENT = undef;

BEGIN {
  my $configFile = "$ENV{'HOME'}/.$ENV{'WORKPRE'}projrc";

  if ( !-f $configFile ) {
    die("Must define a $ENV{'WORKPRE'} projrc file");
  }

  $CONF = YAML::Tiny->read($configFile);
  $CONF = $CONF->[0];

  %SERVICES = map { $_ => $CONF->{'services'}{$_} }
      grep { $CONF->{'services'}{$_}{'id'} }
      keys %{ $CONF->{'services'} };
}

sub GetServices      { return wantarray ? %SERVICES : \%SERVICES; }
sub GetConfiguration { return $CONF; }

sub CreateGitlabClient {
  if ( !defined($CLIENT) ) {
    my $token = qx{ pass $CONF->{'global'}{'access-token'} };
    chomp($token);

    $CLIENT = GitLab::API::v4->new(
      url           => $CONF->{'global'}{'gitlab-api'},
      private_token => $token
    );
  }

  return $CLIENT;
}

sub CreateAwsClient {
  my ($service) = @_;

  my $region = $ENV{'AWS_DEFAULT_REGION'} || 'us-east-1';
  message("Connecting to: $ENV{'AWS_PROFILE'} ($region)");

  my $creds = Paws::Credential::File->new( profile => $ENV{'AWS_PROFILE'} );
  return Paws->service(
    $service,
    credentials => $creds,
    region      => $region,
  );
}

sub CurrentService() {
  my $dir = abs_path();

  my $retval = undef;
  while ( !-d "$dir/.git" and $dir ne '/' ) {
    $dir = dirname($dir);
  }

  my $repo = basename($dir);
  foreach my $svc ( keys %SERVICES ) {
    $retval = $SERVICES{$svc} if ( $repo eq $SERVICES{$svc}{'repo'} );
  }

  return $retval;
}

sub GetWorkList {
  my %opts = @_;

  my @worklist;
  foreach my $svc ( sort keys %SERVICES ) {
    next unless ( exists( $opts{$svc} ) );
    push( @worklist, $SERVICES{$svc} );
  }
  push( @worklist, CurrentService() )
      unless ( scalar(@worklist) );

  return wantarray ? @worklist : \@worklist;
}

1;
