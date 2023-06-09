package Time::Peace;

use strict;
use warnings; no warnings 'once';
use Time::Local;

require Exporter;
our @ISA = 'Exporter';
our @EXPORT_OK = 'now';

use constant {
    SEC   => 0, MIN   =>  1, HOUR => 2,
    DAY   => 3, MON   =>  4, YEAR => 5,
    WDAY  => 6, YDAY  =>  7, DST  => 8,
    EPOCH => 9, LOCAL => 10
};

use overload
  '0+'  => \&epoch,
  '""'  => sub { (shift)->datetime },
  '+'   => sub { (shift)->later( seconds => shift ) },
  '-'   => sub { (shift)->earlier( seconds => shift ) },
  '<=>' => sub { @{ (shift) }[EPOCH] <=> @{ (shift) }[EPOCH] },
;

my @MONTHS = qw(
  January  February  March      April    May       June
  July     August    September  October  November  December
);

my @DAYS = qw( Sunday Monday Tuesday Wednesday Thursday Friday Saturday );

my %MULTIPLIER = (
    seconds => 1,
    minutes => 60,
    hours => 3600,
    days => 86400,
);

sub new {
    my ( $class, @time ) = @_;

    if ( !@time ) {
        @time = localtime
        #@time = gmtime
    }
    elsif ( @time == 1 ) {
        @time = localtime( $time[0] )
        #@time = gmtime( $time[0] )
    }
    else {
        my %time = @time;
        $time{month} -= 1;

        @time = map { $time{$_} } qw( sec min hour day mon year );

        @time = localtime( timelocal( @time ) );
        #@time = gmtime( timegm( @time ) );
    }

    push @time, timelocal( @time );
    #push @time, timegm( @time ); 

    return( bless \@time, $class );
}

sub now { new(__PACKAGE__) }

sub year  { @{ (shift) }[YEAR] + 1900 }
sub mon   { @{ (shift) }[MON]  + 1    }
sub day   { @{ (shift) }[DAY]         }
sub hour  { @{ (shift) }[HOUR]        }
sub min   { @{ (shift) }[MIN]         }
sub sec   { @{ (shift) }[SEC]         }
sub wday  { @{ (shift) }[WDAY]        }
sub yday  { @{ (shift) }[YDAY]        }
sub dst   { @{ (shift) }[DST]         }
sub epoch { @{ (shift) }[EPOCH]       }

*month  = \&mon;
*minute = \&min;
*second = \&sec;

sub ymd {
    my ( $self, $sep ) = ( @_, '-' );
    sprintf(
        join( $sep, qw( %d %02d %02d ) ),
        $self->year, $self->mon, $self->day
    );
}

sub dmy {
    my ( $self, $sep ) = ( @_, '/' );
    sprintf(
        join( $sep, qw( %02d %02d %d ) ),
        $self->day, $self->mon, $self->year
    );
}

sub hms {
    my ( $self, $sep ) = ( @_, ':' );
    sprintf(
        join( $sep, qw( %02d %02d %02d ) ),
        $self->hour, $self->min, $self->sec
    );
}

*time = \&hms;

sub datetime {
    my ( $self, $sep ) = ( @_, 'T' );
    join( $sep, $self->ymd, $self->hms );
}

sub day_name {
    my ( $self ) = @_;
    $DAYS[ $self->wday ];
}

sub day_abbr {
    my ( $self ) = @_;
    substr( $self->day_name, 0, 3 );
}

sub month_name {
    my ( $self ) = @_;
    $MONTHS[ $self->month ];
}

sub month_abbr {
    my ( $self ) = @_;
    substr( $self->month_name, 0, 3 );
}

sub is_leap_year {
    my ( $self ) = @_;
    my $year = $self->year;
    ( $year % 4 == 0 && $year % 100 != 0 ) || $year % 400 == 0;
}

sub tzoffset {
    my ( $self ) = @_;
    timegm(@$self) - $self->epoch;
}

sub offset {
    my ( $self ) = @_;
    my $minutes = $self->tzoffset / 60;
    my $offset = sprintf( '%02d%02d', $minutes / 60, int( $minutes % 60 ) );
    return ( $offset >= 0 ? '+' : '-' ) .  $offset;
}

sub later {
    my ( $self, $key, $value ) = @_;
    my $mult = $MULTIPLIER{ $key } or die;
    my $new = new( __PACKAGE__, $self->epoch + ( $value * $mult ) );
    defined wantarray ? $new : ( @$self = @$new );
}

sub earlier {
    my ( $self, $key, $value ) = @_;
    my $mult = $MULTIPLIER{ $key } or die;
    my $new = new( __PACKAGE__, $self->epoch - ( $value * $mult ) );
    defined wantarray ? $new : ( @$self = @$new );
}

1;
