package Market::Panels::Scales;

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;

    my $self = {

        width =>
            $args{width},

        height =>
            $args{height},

        min_value =>
            $args{min_value},

        max_value =>
            $args{max_value},

        bar_width =>
            $args{bar_width},

        top_padding =>
            $args{top_padding} // 10,

        bottom_padding =>
            $args{bottom_padding} // 10,
    };

    bless $self, $class;

    return $self;
}

# =========================================================
# VALUE -> Y
# =========================================================

sub value_to_y {
    my ($self, $value) = @_;

    my $min =
        $self->{min_value};

    my $max =
        $self->{max_value};

    my $height =
        $self->{height};

    my $top_padding =
        $self->{top_padding};

    my $bottom_padding =
        $self->{bottom_padding};

    my $usable_height =
        $height
        - $top_padding
        - $bottom_padding;

    return $height / 2
        if $max == $min;

    my $normalized =
        ($value - $min)   / ($max - $min);

    my $y =
        $height
        - $bottom_padding
        - ($normalized * $usable_height);

    return $y;
}

# =========================================================
# Y -> VALUE
# =========================================================

sub y_to_value {
    my ($self, $y) = @_;

    my $min =
        $self->{min_value};

    my $max =
        $self->{max_value};

    my $height =
        $self->{height};

    my $top_padding =
        $self->{top_padding};

    my $bottom_padding =
        $self->{bottom_padding};

    my $usable_height =
        $height
        - $top_padding
        - $bottom_padding;

    $y = $top_padding
        if $y < $top_padding;

    $y =
        $height - $bottom_padding
        if $y > (
            $height
            - $bottom_padding
        );

    my $normalized =
        (
            ($height - $bottom_padding)
            - $y
        )
        / $usable_height;

    my $value =
        $min
        + (
            ($max - $min)
            * $normalized
        );

    return $value;
}

# =========================================================
# GETTERS
# =========================================================

sub width {
    my ($self) = @_;

    return $self->{width};
}

sub height {
    my ($self) = @_;

    return $self->{height};
}

sub min_value {
    my ($self) = @_;

    return $self->{min_value};
}

sub max_value {
    my ($self) = @_;

    return $self->{max_value};
}

sub bar_width {
    my ($self) = @_;

    return $self->{bar_width};
}

# =========================================================
# SETTERS
# =========================================================

sub set_width {
    my ($self, $width) = @_;

    $self->{width} = $width;
}

sub set_height {
    my ($self, $height) = @_;

    $self->{height} = $height;
}

sub set_min_value {
    my ($self, $value) = @_;

    $self->{min_value} = $value;
}

sub set_max_value {
    my ($self, $value) = @_;

    $self->{max_value} = $value;
}

sub set_bar_width {
    my ($self, $bar_width) = @_;

    $self->{bar_width} = $bar_width;
}

# =========================================================
# PRICE STEP
# =========================================================

sub compute_price_step {
    my ($self, $steps) = @_;

    $steps ||= 10;

    my $range =
        $self->{max_value}
        - $self->{min_value};

    return 1
        if $range <= 0;

    return $range / $steps;
}

# =========================================================
# NORMALIZE VALUE
# =========================================================

sub normalize_value {
    my ($self, $value) = @_;

    my $min =
        $self->{min_value};

    my $max =
        $self->{max_value};

    return 0
        if $max == $min;

    return
        ($value - $min) / ($max - $min);
}

# =========================================================
# CLAMP Y
# =========================================================

sub clamp_y {
    my ($self, $y) = @_;

    my $top =
        $self->{top_padding};

    my $bottom =
        $self->{height}
        - $self->{bottom_padding};

    $y = $top
        if $y < $top;

    $y = $bottom
        if $y > $bottom;

    return $y;
}

1;