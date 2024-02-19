#! /usr/bin/env perl

use 5.020;
use warnings;
use autodie;

use Getopt::Long;
use JSON;
use YAML::Tiny;

use Toolkit;

my %opts = ();

main();
exit(0);

sub main {

  if ( !GetOptions( \%opts,  'infile=s', 'yaml', 'json')){
    die("Invalid incantation\n");
  }

  foreach my $req (qw( infile )){
    die("must specify a valid $req") unless( $opts{$req} );
  }

  my $obj = {};
  if( $opts{'infile'} =~ /\.(yml|yaml)$/ ){
    $obj =  YAML::Tiny->read($opts{'infile'});
  }elsif( $opts{'infile'} =~ /\.json$/ ){
    my $json = JSON->new->allow_nonref();
    open(my $fh, '<', $opts{'infile'});
    $/ = undef;
    my $text = <$fh>;
    close($fh);
    $obj = $json->decode($text);
  }else{
    message_error("Unable to parse $opts{'infile'}");
  }

  printObject($obj);


}
