package Market::Indicators::ATR;

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;

    my $self = {

        market_data =>
            $args{market_data},

        period =>
            $args{period} || 14,

        values => [],
    };

    bless $self, $class;

    $self->calculate(
        $self->{market_data}
    );

    return $self;
}

# =========================================================
# CALCULATE ATR
# =========================================================

sub calculate {
    my (
        $self,
        $market_data
    ) = @_;

    my $candles =
        $market_data->candles();

    my $period =
        $self->{period};

    my @atr_values;

    return
        unless @$candles;

    # =====================================================
    # TRUE RANGE ARRAY
    # =====================================================

    my @tr_values;

    for my $i (0 .. $#$candles) {

        if ($i == 0) {

            push @tr_values, 0;

            next;
        }

        my $current =
            $candles->[$i];

        my $previous =
            $candles->[$i - 1];

        my $high_low =
            abs(
                $current->{high}
                - $current->{low}
            );

        my $high_close =
            abs(
                $current->{high}
                - $previous->{close}
            );

        my $low_close =
            abs(
                $current->{low}
                - $previous->{close}
            );

        my $tr = $high_low;

        $tr = $high_close
            if $high_close > $tr;

        $tr = $low_close
            if $low_close > $tr;

        push @tr_values, $tr;
    }

    # =====================================================
    # INITIAL ATR
    # =====================================================

    for my $i (0 .. $#tr_values) {

        if ($i < $period) {

            push @atr_values, 0;

            next;
        }

        if ($i == $period) {

            my $sum = 0;

            for my $j (1 .. $period) {

                $sum +=
                    $tr_values[$j];
            }

            my $first_atr =
                $sum / $period;

            push @atr_values,
                $first_atr;

            next;
        }

        # =================================================
        # SMOOTHED ATR
        # =================================================

        my $previous_atr =
            $atr_values[-1];

        my $current_tr =
            $tr_values[$i];

        my $atr =
            (
                (
                    $previous_atr
                    * ($period - 1)
                )
                + $current_tr
            ) / $period;

        push @atr_values, $atr;
    }

    $self->{values} =
        \@atr_values;
}

# =========================================================
# VALUES
# =========================================================

sub values {
    my ($self) = @_;

    return $self->{values};
}

# =========================================================
# PERIOD
# =========================================================

sub period {
    my ($self) = @_;

    return $self->{period};
}

# =========================================================
# SET PERIOD
# =========================================================

sub set_period {
    my (
        $self,
        $period
    ) = @_;

    return
        unless $period > 0;

    $self->{period} =
        $period;

    $self->calculate(
        $self->{market_data}
    );
}

# =========================================================
# LAST VALUE
# =========================================================

sub last_value {
    my ($self) = @_;

    return 0
        unless @{$self->{values}};

    return
        $self->{values}[-1];
}

# =========================================================
# VALUE AT INDEX
# =========================================================

sub value_at {
    my (
        $self,
        $index
    ) = @_;

    return 0
        if $index < 0;

    return 0
        if $index > $#{
            $self->{values}
        };

    return
        $self->{values}[$index];
}

1;