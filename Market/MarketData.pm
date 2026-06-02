package Market::MarketData;

use strict;
use warnings;

use File::Basename qw(dirname);
use lib dirname(dirname(__FILE__));

use Market::TimeframeAggregator;

sub new {
    my ($class, %args) = @_;

    my $self = {

        file =>
            $args{file},

        candles => [],

        _timeframe_data => {},

        _current_timeframe => 1,
    };

    bless $self, $class;

    $self->load_data(
        $self->{file}
    );

    $self->{_active_candles}
        = $self->{candles};

    return $self;
}

# =========================================================
# LOAD CSV DATA
# =========================================================

sub load_data {
    my (
        $self,
        $file
    ) = @_;

    open my $fh, '<', $file
        or die "Cannot open file: $file";

    my $header = <$fh>;

    while (my $line = <$fh>) {

        chomp $line;

        next
            unless $line;

        my @fields =
            split /,/, $line;

        next
            unless @fields >= 6;

        my (
            $time,
            $open,
            $high,
            $low,
            $close,
            $volume
        ) = @fields;

        push @{$self->{candles}}, {

            time =>
                $time,

            open =>
                $open + 0,

            high =>
                $high + 0,

            low =>
                $low + 0,

            close =>
                $close + 0,

            volume =>
                $volume + 0,
        };
    }

    close $fh;
}

# =========================================================
# TIMEFRAME MANAGEMENT
# =========================================================

sub set_timeframe {
    my ($self, $minutes) = @_;

    $self->{_current_timeframe}
        = $minutes;

    if ($minutes <= 1) {

        $self->{_active_candles}
            = $self->{candles};

        return;
    }

    unless (
        exists $self->{_timeframe_data}
            {$minutes}
    ) {

        $self->{_timeframe_data}{$minutes}
            = Market::TimeframeAggregator->aggregate(
                $self->{candles},
                $minutes
            );
    }

    $self->{_active_candles}
        = $self->{_timeframe_data}
            {$minutes};
}

sub get_timeframe {
    my ($self) = @_;

    return
        $self->{_current_timeframe};
}

# =========================================================
# GET ALL CANDLES
# =========================================================

sub candles {
    my ($self) = @_;

    return
        $self->{_active_candles};
}

# =========================================================
# SIZE
# =========================================================

sub size {
    my ($self) = @_;

    return scalar
        @{$self->{_active_candles}};
}

# =========================================================
# GET SINGLE CANDLE
# =========================================================

sub get {
    my (
        $self,
        $index
    ) = @_;

    return undef
        if $index < 0;

    return undef
        if $index > $#{
            $self->{_active_candles}
        };

    return
        $self->{_active_candles}[$index];
}

# =========================================================
# GET SLICE
# =========================================================

sub get_slice {
    my (
        $self,
        $start,
        $end
    ) = @_;

    $start = 0
        if $start < 0;

    $end =
        $#{$self->{_active_candles}}
        if $end > $#{
            $self->{_active_candles}
        };

    return []
        if $start > $end;

    my @slice =
        @{$self->{_active_candles}}[
            $start .. $end
        ];

    return \@slice;
}

# =========================================================
# GET MIN PRICE
# =========================================================

sub get_min_price {
    my (
        $self,
        $start,
        $end
    ) = @_;

    my $slice =
        $self->get_slice(
            $start,
            $end
        );

    return 0
        unless @$slice;

    my $min =
        $slice->[0]{low};

    for my $candle (@$slice) {

        if (
            $candle->{low}
            < $min
        ) {

            $min =
                $candle->{low};
        }
    }

    return $min;
}

# =========================================================
# GET MAX PRICE
# =========================================================

sub get_max_price {
    my (
        $self,
        $start,
        $end
    ) = @_;

    my $slice =
        $self->get_slice(
            $start,
            $end
        );

    return 0
        unless @$slice;

    my $max =
        $slice->[0]{high};

    for my $candle (@$slice) {

        if (
            $candle->{high}
            > $max
        ) {

            $max =
                $candle->{high};
        }
    }

    return $max;
}

# =========================================================
# LAST INDEX
# =========================================================

sub last_index {
    my ($self) = @_;

    return
        $#{$self->{_active_candles}};
}

1;
