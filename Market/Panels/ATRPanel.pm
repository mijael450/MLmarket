package Market::Panels::ATRPanel;

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
    my ($self, $values) = @_;

    my $min = $values->[0];

    my $max = $values->[0];

    for my $v (@$values) {

        if ($v < $min) {

            $min = $v;
        }

        if ($v > $max) {

            $max = $v;
        }
    }

    my $padding =
        ($max - $min) * 0.15;

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
            '#111827',

        -outline =>
            '#111827',

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

    my $horizontal_lines = 5;

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
        $values,
        $scale,
        $engine,
        $offset
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

    my $visible_bars =
        $engine->{visible_bars};

    # =====================================================
    # ATR LABELS
    # =====================================================

    my $min =
        $scale->{min_value};

    my $max =
        $scale->{max_value};

    my $horizontal_lines = 5;

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

            -tags => 'atr_render',
        );
    }

    # =====================================================
    # ATR LINE (viewport-aware)
    # =====================================================

    for my $i (1 .. $#$values) {

        my $prev_global =
            $offset + $i - 1;

        my $curr_global =
            $offset + $i;

        my $prev_vp =
            $prev_global
            - $engine->{offset};

        my $curr_vp =
            $curr_global
            - $engine->{offset};

        next
            if $prev_vp < 0
            && $curr_vp < 0;

        next
            if $prev_vp >= $visible_bars
            && $curr_vp >= $visible_bars;

        my $x1 =
            ($prev_vp * $bar_width)
            + ($bar_width / 2);

        my $x2 =
            ($curr_vp * $bar_width)
            + ($bar_width / 2);

        next
            if $x1 > $chart_width
            && $x2 > $chart_width;

        my $y1 =
            $scale->value_to_y(
                $values->[$i - 1]
            );

        my $y2 =
            $scale->value_to_y(
                $values->[$i]
            );

        $canvas->createLine(

            $x1,
            $y1,
            $x2,
            $y2,

            -fill => '#f59e0b',

            -width => 2,

            -smooth => 1,

            -tags => 'atr_render',
        );
    }

    # =====================================================
    # TITLE
    # =====================================================

    my $tf = $engine->{market_data}->get_timeframe();

    $canvas->createText(

        10,
        10,

        -text => "ATR (14) - ${tf}m",

        -anchor => 'w',

        -fill => '#f59e0b',

        -font => [
            'Arial',
            10,
            'bold'
        ],

        -tags => 'atr_render',
    );
}

# =========================================================
# CROSSHAIR LABELS
# =========================================================

sub render_crosshair_labels {
    my (
        $self,
        $canvas,
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

    my $snapped_x =
        $engine->{crosshair_snapped_x};

    my $my_atr =
        $engine->{mouse_y_atr};

    my $my =
        defined $my_atr
        ? $my_atr
        : $engine->{mouse_y};

    return
        unless defined $snapped_x
        && defined $my;

    return
        unless $snapped_x >= 0
        && $snapped_x <= $chart_width
        && $my >= 0
        && $my <= $chart_height;

    my $atr_value =
        $scale->y_to_value($my);

    # =====================================================
    # RIGHT VALUE LABEL
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
            sprintf("%.2f", $atr_value),

        -fill => '#ffffff',

        -font => [
            'Arial',
            9,
            'bold'
        ],

        -tags => 'crosshair',
    );

    # =====================================================
    # TIME LABEL (sincronizada)
    # =====================================================

    my $index =
        $engine->{crosshair_index};

    my $data =
        $engine->{_last_data};

    if (
        defined $index
        && defined $data
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
