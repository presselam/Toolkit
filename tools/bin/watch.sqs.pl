#! /usr/bin/env perl

use 5.020;
use warnings;
use autodie;

use Getopt::Long;
use JSON;
use Paws;
use Paws::Credential::File;
use Term::ANSIScreen qw( cls locate );

use Toolkit;

my $active = 1;
$SIG{'INT'} = sub{
  $active = 0;
  say("\r         "); # just being lazy
};

my %opts = ( 'sleep' => 10 );
if ( !GetOptions( \%opts, 'queue=s', 'sleep=i', 'commit' ) ) {
  die("Invalid incantation\n");
}

main();
exit(0);

sub main {

  foreach my $req (qw{ queue }) {
    die("must specify a valid: $req") unless ( exists( $opts{$req} ) );
  }

  my $json = JSON->new->allow_nonref();

  my $creds = Paws::Credential::File->new(
    profile          => $ENV{'AWS_PROFILE'},
    credentials_file => "$ENV{'HOME'}/.aws/credentials",
  );

  my $sqs
      = Paws->service( 'SQS', credentials => $creds, region => 'us-east-1' );

  my $rc;
  eval { $rc = $sqs->GetQueueUrl( QueueName => $opts{'queue'} ); };
  if ($@) {
    warn("error: $@");
    exit 1;
  }

  my $qUrl = $rc->{'QueueUrl'};

  while ($active) {
    my $timeOut = $opts{'sleep'};
    print( cls(), locate( 1, 1 ) );

    my $attr = $sqs->GetQueueAttributes(
      QueueUrl       => $qUrl,
      AttributeNames => ['All']
    );
    $attr = $attr->{'Attributes'};
    message(
      $opts{'queue'},
      "  Messages: $attr->{'ApproximateNumberOfMessages'}",
      "  Inflight: $attr->{'ApproximateNumberOfMessagesNotVisible'}",
      " Visiblity: $attr->{'VisibilityTimeout'}"
    );

    my $resp = $sqs->ReceiveMessage( QueueUrl => $qUrl );

    foreach my $msg ( @{ $resp->{'Messages'} } ) {
      message("Message: $msg->{'MessageId'}");
      my $body = $msg->{'Body'};
      printObject( $json->decode($body) );

      if ( $opts{'commit'} ) {
        message("Removing: $msg->{'MessageId'}");
        $resp = $sqs->DeleteMessage(
          QueueUrl      => $qUrl,
          ReceiptHandle => $msg->{'ReceiptHandle'}
        );
      }

      $timeOut = $attr->{'VisibilityTimeout'};
    }

    sleep $timeOut;
  }

}

__END__ 

=head1 NAME

watch.sqs.pl - [description here]

=head1 VERSION

This documentation refers to watch.sqs.pl version 0.0.1

=head1 USAGE

    watch.sqs.pl [options]

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

Copyright (c) 2023, Andrew Pressel C<< <apressel@nextgenfed.com> >>. All rights reserved.

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

