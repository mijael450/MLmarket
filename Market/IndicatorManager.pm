package Market::IndicatorManager;

use strict;
use warnings;

use File::Basename qw(dirname);
use lib dirname(dirname(__FILE__));

use Market::Indicators::ATR;

sub new {
    my ($class, %args) = @_;

    my $self = {

        market_data =>
            $args{market_data},

        indicators => {},
    };

    bless $self, $class;

    $self->initialize_indicators();

    return $self;
}

# =========================================================
# INITIALIZE
# =========================================================

sub initialize_indicators {
    my ($self) = @_;

    $self->{indicators}{atr}
        = Market::Indicators::ATR->new(

            market_data =>
                $self->{market_data},

            period => 14,
        );
}

# =========================================================
# GET INDICATOR
# =========================================================

sub get_indicator {
    my ($self, $name) = @_;

    return
        $self->{indicators}{$name};
}

# =========================================================
# GET VALUES
# =========================================================

sub get_values {
    my ($self, $name) = @_;

    my $indicator =
        $self->get_indicator($name);

    return []
        unless $indicator;

    return
        $indicator->values();
}

# =========================================================
# SLICE ARRAY
# =========================================================

sub slice_array {
    my (
        $self,
        $name,
        $start,
        $end
    ) = @_;

    my $values =
        $self->get_values($name);

    return []
        unless @$values;

    $start = 0
        if $start < 0;

    $end = $#$values
        if $end > $#$values;

    my @slice =
        @$values[
            $start .. $end
        ];

    return \@slice;
}

# =========================================================
# UPDATE ALL
# =========================================================

sub update_all {
    my ($self) = @_;

    for my $name (
        keys %{
            $self->{indicators}
        }
    ) {

        my $indicator =
            $self->{indicators}{$name};

        $indicator->calculate(
            $self->{market_data}
        );
    }
}

# =========================================================
# HAS INDICATOR
# =========================================================

sub has_indicator {
    my ($self, $name) = @_;

    return exists
        $self->{indicators}{$name};
}

# =========================================================
# LIST INDICATORS
# =========================================================

sub list_indicators {
    my ($self) = @_;

    return keys %{
        $self->{indicators}
    };
}

1;