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
        $engine,
        $offset
    ) = @_;

    $self->{scale} = $scale;

    $scale->snap_to_nice();

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

    my $visible_bars =
        $engine->{visible_bars};

    # =====================================================
    # PRICE LABELS (nice increments)
    # =====================================================

    my $min =
        $scale->{min_value};

    my $max =
        $scale->{max_value};

    my $horizontal_lines = 10;

    my $price_step =
        ($max - $min) / $horizontal_lines;

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
    # TIME LABELS (pivot primer candle del dia)
    # =====================================================

    my $count =
        scalar @$data;

    if ($count > 0) {

        my @label_indices;
        my $prev_date = '';

        for my $i (0 .. $count - 1) {

            my $date =
                substr(
                    $data->[$i]{time},
                    0,
                    10
                );

            if (
                $date ne $prev_date
            ) {

                push @label_indices,
                    $i;

                $prev_date = $date;
            }
        }

        # Ultima vela historica como pivot
        if (
            @label_indices == 0
            || $label_indices[-1]
            != $count - 1
        ) {

            push @label_indices,
                $count - 1;
        }

        # Limitar a 6 etiquetas
        my $max_labels = 6;

        if (
            @label_indices
            > $max_labels
        ) {

            my @sampled =
                ($label_indices[0]);

            my $step =
                ($label_indices[-1]
                - $label_indices[0])
                / ($max_labels - 1);

            for my $j (
                1 .. $max_labels - 2
            ) {

                push @sampled,
                    $label_indices[
                        int(
                            $j * $step
                        )
                    ];
            }

            push @sampled,
                $label_indices[-1];

            @label_indices =
                @sampled;
        }

        for my $idx (@label_indices) {

            next
                if $idx >= $count;

            my $candle =
                $data->[$idx];

            my $global_idx =
                $offset + $idx;

            my $viewport_idx =
                $global_idx
                - $engine->{offset};

            next
                if $viewport_idx < 0;

            next
                if $viewport_idx
                >= $visible_bars;

            my $x =
                (
                    $viewport_idx
                    * $bar_width
                ) + ($bar_width / 2);

            next
                if $x > $chart_width;

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
    }

    # =====================================================
    # CANDLES
    # =====================================================

    for my $i (0 .. $#$data) {

        my $candle =
            $data->[$i];

        my $global_idx =
            $offset + $i;

        my $viewport_idx =
            $global_idx
            - $engine->{offset};

        next
            if $viewport_idx < 0;

        next
            if $viewport_idx
            >= $visible_bars;

        my $x =
            (
                $viewport_idx
                * $bar_width
            ) + ($bar_width / 2);

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

    my $my =
        $engine->{mouse_y};

    my $snapped_x =
        $engine->{crosshair_snapped_x};

    my $index =
        $engine->{crosshair_index};

    return
        unless defined $snapped_x
        && defined $my;

    return
        unless $snapped_x >= 0
        && $snapped_x <= $chart_width
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
    # TIME LABEL (snapped)
    # =====================================================

    if (
        defined $index
        && $index >= 0
        && $index < @$data
    ) {

        my $time =
            $data->[$index]{time};

        $canvas->createRectangle(

            $snapped_x - 40,
            $chart_height,
            $snapped_x + 40,
            $height,

            -fill =>
                '#334155',

            -outline =>
                '#334155',

            -tags => 'crosshair',
        );

        $canvas->createText(

            $snapped_x,
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
