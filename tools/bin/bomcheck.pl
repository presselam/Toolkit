#! /usr/bin/env perl

use 5.020;
use warnings;
use autodie;

use Fcntl qw( SEEK_SET );
use File::Copy;
use File::Find;
use Getopt::Long;

use Toolkit;

my %opts;
if ( !GetOptions( \%opts, 'infile=s', 'directory=s', 'commit' ) ) {
  die("Invalid incantation\n");
}

main();
exit(0);

sub main {

  my $start = $opts{'infile'} || $opts{'directory'} || undef;
  if ( !defined($start) ) {
    die("must specify either a infile or directory");
  }

  find( \&bomcheck, $start );
}

sub bomcheck {
  return unless ( -f $_ );
  return if( $_ =~ /\.bom$/ );
  open( my $fh, '<:bytes', $_ );

  my $bom = '';
  my $rc = sysread( $fh, $bom, 4, 0 );
  $bom = unpack( 'H*', $bom );

  my $found = undef;
  my $sz    = undef;
  if ( $bom =~ /^efbbbf/i )   { $found = 'UTF-8';    $sz = 3; }
  if ( $bom =~ /^fffe/i )     { $found = 'UTF-16le'; $sz = 2; }
  if ( $bom =~ /^feff/i )     { $found = 'UTF-16be'; $sz = 2; }
  if ( $bom =~ /^0000feff/i ) { $found = 'UTF-32be'; $sz = 4; }
  if ( $bom =~ /^fffe0000/i ) { $found = 'UTF-32le'; $sz = 4; }

  if ( defined($found) ) {
    say("$found BOM Found: $File::Find::name");
    if ( exists( $opts{'commit'} ) ) {
      open( my $outfh, '>:bytes', "$_.clean" );

      my $buffer;
      sysseek( $fh, $sz, SEEK_SET );
      while ( sysread( $fh, $buffer, 1024 * 1024 ) ) {
        $outfh->print($buffer);
      }
      close($outfh);
      move( $_,         "$_.bom" );
      move( "$_.clean", $_ );
    }
  }
  close($fh);
}

__END__

=head1 NAME

bomcheck.pl - [description here]

=head1 VERSION

This documentation refers to bomcheck.pl version 0.0.1

=head1 USAGE

    bomcheck.pl [options]

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

Copyright (c) 2017, Andrew Pressel C<< <apressel@nextgenfed.com> >>. All rights reserved.

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

