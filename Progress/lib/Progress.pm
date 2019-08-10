package Progress;

use 5.010000;
use strict;

use base qw( Exporter );
use Time::HiRes qw( time );

use Utilities qw( convertSeconds );

our $VERSION = '0.01';

sub new {
    my ($class) = shift;
    my $self = {@_};

    foreach my $req (qw( how_many )) {
        die("Must specify [$req] parameter\n")
            unless( exists( $self->{$req} ) );
    }

    $self->{'how_often'} = 10 unless( exists( $self->{'how_often'} ) );
    $self->{'marker'}    = $self->{'how_often'};
    $self->{'header'}    = "Count    %   Elapsed Remaining Rate\n",
        push( @{ $self->{'TIMESTAMPS'} }, time() );

    return bless( $self, $class );
}

sub tick {
    my ( $self, %info ) = @_;

    push( @{ $self->{'TIMESTAMPS'} }, time() );

    my $i = scalar( @{ $self->{'TIMESTAMPS'} } ) - 1;
    if( int( ( $i / $self->{'how_many'} ) * 100 ) >= $self->{'marker'} ) {
        $self->print_stats(%info) unless( $self->{'noprint'} );
        $self->{'marker'} += $self->{'how_often'};
    }
}

sub print_stats {
    my ( $self, %info ) = @_;

    my $stats = $self->calc_stats(%info);

    printf(
        "%s%5d %3d%% %9.9s %9.9s %.2f\n",
        $self->{header},
        $stats->{'Completed'},
        $stats->{'Percent'},
        $stats->{'Elapsed'},
        $stats->{'ETA'},
        $stats->{'Rate'}
    );
    $self->{'header'} = '';

#    print( $_, ' ' x ( $space - length($_) ), " => $stats->{$_}\n" )
#        foreach (qw(Completed Remaining Elapsed Mean First Last ETA));
#    print( $_, ' ' x ( $space - length($_) ), " => $stats->{$_}\n" )
#        foreach sort keys %info;
}

sub calc_stats {
    my ( $self, %info ) = @_;

    my $samples = $self->{'TIMESTAMPS'};
    my $count   = scalar( @{$samples} ) - 1;
    my $left    = $self->{'how_many'} - $count;

    my $min = $samples->[0];
    my $max = $samples->[-1];

    my $delta = $max - $min;
    my $avg   = int( $delta / $count );

    my $expected;
    if( $avg == 0 ) {
        $expected = $left;
    } else {
        $expected = $avg * $left;
    }

    my %summary = (
        %info,
        Remaining => $left,
        Completed => $count,
        Percent => int(($count/$self->{'how_many'}) *100),
        First     => scalar( localtime($min) ),
        Last      => scalar( localtime($max) ),
        Elapsed   => convertSeconds($delta),
        Mean      => convertSeconds($avg),
        Rate => $count/$delta,
        ETA       => convertSeconds($expected),
    );

    return wantarray ? %summary : \%summary;
}
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Progress - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Progress;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Progress, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

A. U. Thor, E<lt>apressel@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by A. U. Thor

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
