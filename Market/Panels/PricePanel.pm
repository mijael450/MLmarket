package Market::Panels::PricePanel;

use strict;
use warnings;

sub new {
    my ($class) = @_;

    my $self = {

        scale => undef,
    };

    bless $self, $class;

    return $self;
}

# =========================================================
# SCALE
# =========================================================

sub set_scale {
    my ($self, $scale) = @_;

    $self->{scale} = $scale;
}

# =========================================================
# Y RANGE
# =========================================================

sub get_y_range {
    my ($self, $data) = @_;

    my $min =
        $data->[0]{low};

    my $max =
        $data->[0]{high};

    for my $candle (@$data) {

        if (
            $candle->{low}
            < $min
        ) {

            $min =
                $candle->{low};
        }

        if (
            $candle->{high}
            > $max
        ) {

            $max =
                $candle->{high};
        }
    }

    my $padding =
        ($max - $min) * 0.05;

    $min -= $padding;

    $max += $padding;

    return ($min, $max);
}

# =========================================================
# RENDER STATIC
# =========================================================

sub render_static {
    my (
        $self,
        $canvas,
        $engine
    ) = @_;

    my $width =
        $canvas->Width;

    my $height =
        $canvas->Height;

    my $right_axis_width =
        $engine->{right_axis_width};

    my $bottom_axis_height =
        $engine->{bottom_axis_height};

    my $chart_width =
        $width
        - $right_axis_width;

    my $chart_height =
        $height
        - $bottom_axis_height;

    # =====================================================
    # BACKGROUND
    # =====================================================

    $canvas->createRectangle(

        0,
        0,
        $width,
        $height,

        -fill =>
            $engine->{background_color},

        -outline =>
            $engine->{background_color},

        -tags => 'static_render',
    );

    # =====================================================
    # RIGHT AXIS BACKGROUND
    # =====================================================

    $canvas->createRectangle(

        $chart_width,
        0,
        $width,
        $chart_height,

        -fill =>
            $engine->{axis_background},

        -outline =>
            $engine->{grid_color},

        -tags => 'static_render',
    );

    # =====================================================
    # BOTTOM AXIS BACKGROUND
    # =====================================================

    $canvas->createRectangle(

        0,
        $chart_height,
        $chart_width,
        $height,

        -fill =>
            $engine->{axis_background},

        -outline =>
            $engine->{grid_color},

        -tags => 'static_render',
    );

    # =====================================================
    # GRID
    # =====================================================

    my $horizontal_lines = 10;

    my $vertical_lines = 12;

    for my $i (0 .. $horizontal_lines) {

        my $y =
            ($chart_height
            / $horizontal_lines)
            * $i;

        $canvas->createLine(

            0,
            $y,
            $chart_width,
            $y,

            -fill =>
                $engine->{grid_color},

            -tags => 'static_render',
        );
    }

    for my $i (0 .. $vertical_lines) {

        my $x =
            ($chart_width
            / $vertical_lines)
            * $i;

        $canvas->createLine(

            $x,
            0,
            $x,
            $chart_height,

            -fill =>
                $engine->{grid_color},

            -tags => 'static_render',
        );
    }
}

# =========================================================
# RENDER DYNAMIC
# =========================================================

sub render_dynamic {
    my (
        $self,
        $canvas,
        $data,
        $scale,
        $engine
    ) = @_;

    $self->{scale} = $scale;

    my $width =
        $canvas->Width;

    my $height =
        $canvas->Height;

    my $right_axis_width =
        $engine->{right_axis_width};

    my $bottom_axis_height =
        $engine->{bottom_axis_height};

    my $chart_width =
        $width
        - $right_axis_width;

    my $chart_height =
        $height
        - $bottom_axis_height;

    my $bar_width =
        $scale->{bar_width};

    # =====================================================
    # PRICE LABELS
    # =====================================================

    my $min =
        $scale->{min_value};

    my $max =
        $scale->{max_value};

    my $horizontal_lines = 10;

    for my $i (0 .. $horizontal_lines) {

        my $y =
            ($chart_height
            / $horizontal_lines)
            * $i;

        my $value =
            $max
            - (
                ($max - $min)
                * ($i / $horizontal_lines)
            );

        $canvas->createText(

            $chart_width + 45,
            $y,

            -text =>
                sprintf("%.2f", $value),

            -fill =>
                $engine->{text_color},

            -font => [
                'Arial',
                9
            ],

            -tags => 'price_render',
        );
    }

    # =====================================================
    # TIME LABELS
    # =====================================================

    my $count =
        scalar @$data;

    my $vertical_lines = 12;

    for my $i (0 .. $vertical_lines - 1) {

        my $index =
            int(
                ($count - 1)
                * ($i / $vertical_lines)
            );

        next
            if $index >= $count;

        my $candle =
            $data->[$index];

        my $x =
            ($index * $bar_width)
            + ($bar_width / 2);

        $canvas->createText(

            $x,
            $chart_height + 14,

            -text =>
                $candle->{time},

            -fill =>
                $engine->{text_color},

            -font => [
                'Arial',
                8
            ],

            -anchor => 'n',

            -tags => 'price_render',
        );
    }

    # =====================================================
    # CANDLES
    # =====================================================

    for my $i (0 .. $#$data) {

        my $candle =
            $data->[$i];

        my $x =
            ($i * $bar_width)
            + ($bar_width / 2);

        next
            if $x < 0;

        next
            if $x > $chart_width;

        my $open_y =
            $scale->value_to_y(
                $candle->{open}
            );

        my $close_y =
            $scale->value_to_y(
                $candle->{close}
            );

        my $high_y =
            $scale->value_to_y(
                $candle->{high}
            );

        my $low_y =
            $scale->value_to_y(
                $candle->{low}
            );

        my $bullish =
            $candle->{close}
            >= $candle->{open};

        my $color =
            $bullish
            ? $engine->{bullish_color}
            : $engine->{bearish_color};

        # =================================================
        # WICK
        # =================================================

        $canvas->createLine(

            $x,
            $high_y,
            $x,
            $low_y,

            -fill => $color,

            -width => 1,

            -tags => 'price_render',
        );

        # =================================================
        # BODY
        # =================================================

        my $top =
            $open_y < $close_y
            ? $open_y
            : $close_y;

        my $bottom =
            $open_y > $close_y
            ? $open_y
            : $close_y;

        if (
            abs($bottom - $top)
            < 1
        ) {

            $bottom =
                $top + 1;
        }

        $canvas->createRectangle(

            $x - ($bar_width * 0.35),

            $top,

            $x + ($bar_width * 0.35),

            $bottom,

            -fill => $color,

            -outline => $color,

            -tags => 'price_render',
        );
    }

}

# =========================================================
# CROSSHAIR LABELS
# =========================================================

sub render_crosshair_labels {
    my (
        $self,
        $canvas,
        $data,
        $scale,
        $engine
    ) = @_;

    my $width =
        $canvas->Width;

    my $height =
        $canvas->Height;

    my $right_axis_width =
        $engine->{right_axis_width};

    my $bottom_axis_height =
        $engine->{bottom_axis_height};

    my $chart_width =
        $width
        - $right_axis_width;

    my $chart_height =
        $height
        - $bottom_axis_height;

    my $bar_width =
        $scale->{bar_width};

    my $mx =
        $engine->{mouse_x};

    my $my =
        $engine->{mouse_y};

    return
        unless defined $mx
        && defined $my;

    return
        unless $mx >= 0
        && $mx <= $chart_width
        && $my >= 0
        && $my <= $chart_height;

    my $price =
        $scale->y_to_value($my);

    # =====================================================
    # RIGHT PRICE LABEL
    # =====================================================

    $canvas->createRectangle(

        $chart_width,
        $my - 10,
        $width,
        $my + 10,

        -fill =>
            '#334155',

        -outline =>
            '#334155',

        -tags => 'crosshair',
    );

    $canvas->createText(

        $chart_width + 45,
        $my,

        -text =>
            sprintf("%.2f", $price),

        -fill => '#ffffff',

        -font => [
            'Arial',
            9,
            'bold'
        ],

        -tags => 'crosshair',
    );

    # =====================================================
    # TIME LABEL
    # =====================================================

    my $index =
        int($mx / $bar_width);

    if (
        $index >= 0
        && $index < @$data
    ) {

        my $time =
            $data->[$index]{time};

        $canvas->createRectangle(

            $mx - 40,
            $chart_height,
            $mx + 40,
            $height,

            -fill =>
                '#334155',

            -outline =>
                '#334155',

            -tags => 'crosshair',
        );

        $canvas->createText(

            $mx,
            $chart_height + 14,

            -text => $time,

            -fill => '#ffffff',

            -font => [
                'Arial',
                8,
                'bold'
            ],

            -tags => 'crosshair',
        );
    }
}

1;
