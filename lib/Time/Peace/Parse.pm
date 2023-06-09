package Time::Peace::Parse;

use v5.26;
use warnings;
use experimental 'signatures';

my %FORMAT = (

    # Abbreviated weekday
    a => qr{(Sun|Mon|Tue|Wed|Thu|Fri|Sat)}i,

    # Full weekday
    A => qr{((?:Sun|Mon|Tues|Wednes|Thurs|Fri|Satur)day)}i,

    # Abbreviated month
    b => qr{(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)}i,

    # Full month
    B => qr{((?:Jan|Febr)uary|March|April|May|June|July|August|(?:Septem|Octo|Novem|Decem)ber)}i,

    # Day of month - zero
    d => qr{(0?[1-9]|[1-2][0-9]|3[0-1])},

    # Day of month - space
    e => qr{( [1-9]|[1-2][0-9]|3[0-1])},

    # Day of month - suffix
    E => qr{(?:([1-9]|[1-2][0-9]|3[0-1])(?:st|nd|rd|th))}i,

    # Same as b
    h => qr{(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)}i,

    # 24 Hour - zero
    H => qr{([0-1][0-9]|2[0-3])},

    # 12 Hour - zero
    I => qr{(0?[1-9]|1[0-2])},

    # 24 Hour - space
    k => qr{( [0-9]|1[0-9]|2[0-3])},

    # 12 Hour - space
    l => qr{( [1-9]|1[0-2])},

    # Month number
    m => qr{(0[1-9]|1[0-2])},

    # Minute number
    M => qr{([0-5][0-9])},

    # AM or PM
    p => qr{([AP]M)},

    # am or pm
    P => qr{([ap]m)},

    # Second number
    S => qr{([0-5][0-9]|60)},

    # Weekday number
    w => qr{([0-6])},

    # Week number
    W => qr{(0[1-9]|[1-4][0-9]|5[0-3])},

    # Year - short
    y => qr{(\d\d)},

    # Year - long
    Y => qr{(\d{0,2}\d\d)},

    # GMT adjustment
    z => qr{([-+]?\d\d\d\d)},

    # Olson zone
    Z => qw{([A-Z]+)},

    # Literal %
    '%' => qr{(%)},
);

my %MONTH = (

    # General purpose month lookup
    # substr( lc $month, 0, 3 ) to look up month by name

    # Number from name
    jan => '01', feb => '02', mar => '03', apr => '04', may => '05', jun => '06',
    jul => '07', aug => '08', sep => '09', oct => '10', nov => '11', dec => '12',

    # Name from number
    '01' => 'January',   '02' => 'February', '03' => 'March',    '04' => 'April', 
    '05' => 'May',       '06' => 'June',     '07' => 'July',     '08' => 'August', 
    '09' => 'September', '10' => 'October',  '11' => 'November', '12' => 'December', 
);

my $ISO_8601 = "%Y-%m-%dT%H:%M:%S";

sub parser( $class, $string, $format = $ISO_8601 ) {

    my ( %fields, @fields, $convert );

    $convert = sub {
        my $fmt = shift or return '';
        my $n = index( $fmt, '%' );
        my $token = substr( $fmt, $n + 1, 1 );
        if ( my $re = $FORMAT{$token} ) {
            push @fields, $token;
            return
            substr( $fmt, 0, $n )
            . $re
            . $convert->( substr( $fmt, $n + 2 ) );
        }
        else {
            return
            substr( $fmt, 0, $n + 2 )
            . $convert->( substr( $fmt, $n + 2 ) );
        }
    };

    my $regex = $convert->($format);
    $regex = qr{^$regex$};

    if ( my @capture = $string =~ $regex ) {
        my $i;
        for my $token (@fields) {
            $fields{$token} = $capture[ $i++ ];
        }
    }
    else {
        die "Format does not match string";
        return;
    }

    # Parse year
    my $year = $fields{Y} || $fields{y} || croak("No year supplied");

    # Parse month
    if ( !$fields{m} ) {
        my $month = $fields{b} || $fields{B} || die("no month");
        $fields{m} = $MONTH{ lc substr( $month, 0, 3 ) };
    }
    my $mon = $fields{m} || 1;

    # Parse day of month
    if ( !$fields{d} ) {
        my $day = $fields{e} || $fields{E} || die("no day");
        $day = int($day);
        if ( length $day < 2 ) {
            $day = $day;
        }
        $day =~ s{[^\d]}{}g;
        $fields{d} = $day;
    }
    my $day = $fields{d} || 1;

    # Parse hours
    if ( !$fields{H} ) {
        my $hour = $fields{I} || 0;
        my $meridiem = $fields{p} || $fields{P} || undef;
        if ( $meridiem ) {
            if ( index( 'AM', uc $meridiem ) >= 0 && $hour == 12 ) {
                $hour = 0;
            }
            elsif ( index( 'PM', uc $meridiem ) >= 0 ) {
                $hour += 12;
            }
        }
        $fields{H} = $hour;
    }
    my $hour = $fields{H};

    # Parse minutes
    if ( !$fields{M} ) {
        $fields{M} = 0;
    }
    my $min = $fields{M};

    # Parse seconds
    if ( !$fields{S} ) {
        $fields{S} = 0;
    }
    my $sec = $fields{S};

    my @time = (
        map { 0 + $_ }
        $sec, $min,  $hour,
        $day, $mon - 1, $year - 1900,
    );

    return @time;
}
