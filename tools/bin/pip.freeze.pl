#! /usr/bin/env perl

use 5.020;
use warnings;
use autodie;

use Getopt::Long;
use JSON;

use Toolkit;

my %opts;
if ( !GetOptions( \%opts, 'verbose', 'commit' ) ) {
  die("Invalid incantation\n");
}

main();
exit(0);

sub main {

  if ( -f 'requirements.txt' ) {
    pipreq_freeze();
  } elsif ( -f 'Pipfile.lock' ) {
    pipfile_freeze();
  } else {
    message("Unable to find pip dependencies");
  }
}

sub pipreq_freeze(){
  my @deps = qx{ pip freeze };
  chomp(@deps);
  my %map = map{ split('==', $_) } @deps;
  printObject(\%map) if( exists($opts{'verbose'}) );

  open(my $fh, '<', 'requirements.txt');
  while(my $ln = <$fh>){
    chomp($ln);
    next if( $ln =~ /^\s*(#|$)/ );

    my ($pkg,$ver) = $ln =~ /^\s*([a-zA-Z0-9\-_]+)(.*)$/;
    if ( exists( $map{$pkg} ) ) {
      say("$pkg==$map{$pkg}");
    } else {
      quick("unable to find frozen version for [$pkg]");
      say($pkg);
    }
  }

  close($fh);
}

sub pipfile_freeze {

  my $json_text;
  open( my $fh, '<', 'Pipfile.lock' );
  {
    local $/ = undef;
    $json_text = <$fh>;
  }
  close($fh);

  my $json = JSON->new->allow_nonref();
  my $obj  = $json->decode($json_text);

  #  printObject($obj);

  my %default = map { $_ => $obj->{'default'}{$_}{'version'} }
      keys %{ $obj->{'default'} };
  my %develop = map { $_ => $obj->{'develop'}{$_}{'version'} }
      keys %{ $obj->{'develop'} };
  my %map = ( %default, %develop );
  printObject( \%map ) if( exists($opts{'verbose'}) );

  open( $fh, '<', 'Pipfile' );
  my $wanted = 0;
  while ( my $ln = <$fh> ) {
    chomp($ln);
    next if ( $ln =~ /^\s*$/ );
    next if ( $ln =~ /^\s*#/ );

    $wanted = 0 if ( $ln =~ /^\[/ );
    if ( $ln =~ /\[(packages|dev-packages)\]/ ) {
      message($1);
      $wanted = 1;
      next;
    }

    next unless ($wanted);
    my ( $pkg, $ver ) = split( /\s*=\s*/, $ln );
    if ( exists( $map{$pkg} ) ) {
      say(qq{$pkg = "$map{$pkg}"});
    } else {
      quick("unable to find frozen version for [$pkg]");
      say(qq{$pkg = "*"});
    }
  }
  close($fh);

}

__END__ 

=head1 NAME

/home/apressel/bin/pip.freeze.pl - [description here]

=head1 VERSION

This documentation refers to /home/apressel/bin/pip.freeze.pl version 0.0.1

=head1 USAGE

    /home/apressel/bin/pip.freeze.pl [options]

=head1 REQUIRED ARGUMENTS

=over

None

=back

=head1 OPTIONS

=over

None

=back

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

Requires no configuration files or environment variables.


=head1 DEPENDENCIES

None.


=head1 BUGS

None reported.
Bug reports and other feedback are most welcome.


=head1 AUTHOR

Andrew Pressel C<< apressel@nextgenfed.com >>


=head1 COPYRIGHT

Copyright (c) 2022, Andrew Pressel C<< <apressel@nextgenfed.com> >>. All rights reserved.

This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
(see http://www.perl.com/perl/misc/Artistic.html)


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

