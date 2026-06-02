package Market::ChartEngine;

use strict;
use warnings;

use File::Basename qw(dirname);
use lib dirname(dirname(__FILE__));

use Market::Panels::PricePanel;
use Market::Panels::ATRPanel;
use Market::Panels::Scales;

sub new {
    my ($class, %args) = @_;

    my $self = {

        # =====================================================
        # CORE DATA
        # =====================================================

        market_data =>
            $args{market_data},

        indicator_manager =>
            $args{indicator_manager},

        # =====================================================
        # CANVASES
        # =====================================================

        price_canvas =>
            $args{price_canvas},

        atr_canvas =>
            $args{atr_canvas},

        # =====================================================
        # PANELS
        # =====================================================

        price_panel =>
            Market::Panels::PricePanel->new(),

        atr_panel =>
            Market::Panels::ATRPanel->new(),

        # =====================================================
        # VIEWPORT
        # =====================================================

        visible_bars => 120,

        offset => 0,

        min_visible_bars => 20,

        max_visible_bars => 300,

        right_axis_width => 90,

        bottom_axis_height => 28,

        top_padding => 20,

        left_padding => 10,

        atr_height => 220,

        # =====================================================
        # VERTICAL ZOOM
        # =====================================================

        vertical_zoom => 1.0,

        min_vertical_zoom => 0.3,

        max_vertical_zoom => 5.0,

        # =====================================================
        # INTERACTION
        # =====================================================

        dragging => 0,

        drag_start_x => 0,

        drag_initial_offset => 0,

        mouse_x => undef,

        mouse_y => undef,

        crosshair_index => undef,

        # =====================================================
        # COLORS
        # =====================================================

        background_color => '#0f172a',

        grid_color => '#1e293b',

        bullish_color => '#26a69a',

        bearish_color => '#ef5350',

        text_color => '#94a3b8',

        crosshair_color => '#64748b',

        axis_background => '#111827',
    };

    bless $self, $class;

    return $self;
}

# =========================================================
# EVENT BINDING
# =========================================================

sub bind_events {
    my ($self) = @_;

    my @canvases = (
        $self->{price_canvas},
        $self->{atr_canvas}
    );

    for my $canvas (@canvases) {

        # =====================================================
        # WINDOWS ZOOM
        # =====================================================

        $canvas->CanvasBind(

            '<MouseWheel>' => sub {

                my $event = $Tk::event;

                if ($event->delta > 0) {

                    $self->zoom_in($event->x);

                } else {

                    $self->zoom_out($event->x);
                }
            }
        );

        # =====================================================
        # LINUX ZOOM
        # =====================================================

        $canvas->CanvasBind(

            '<Button-4>' => sub {

                my $event = $Tk::event;

                $self->zoom_in($event->x);
            }
        );

        $canvas->CanvasBind(

            '<Button-5>' => sub {

                my $event = $Tk::event;

                $self->zoom_out($event->x);
            }
        );

        # =====================================================
        # CTRL ZOOM VERTICAL (WINDOWS)
        # =====================================================

        $canvas->CanvasBind(

            '<Control-MouseWheel>' => sub {

                my $event = $Tk::event;

                if ($event->delta > 0) {

                    $self->zoom_vertical_in();

                } else {

                    $self->zoom_vertical_out();
                }
            }
        );

        # =====================================================
        # CTRL ZOOM VERTICAL (LINUX)
        # =====================================================

        $canvas->CanvasBind(

            '<Control-Button-4>' => sub {

                $self->zoom_vertical_in();
            }
        );

        $canvas->CanvasBind(

            '<Control-Button-5>' => sub {

                $self->zoom_vertical_out();
            }
        );

        # =====================================================
        # DRAG START
        # =====================================================

        $canvas->CanvasBind(

            '<ButtonPress-1>' => sub {

                my $event = $Tk::event;

                $self->{dragging} = 1;

                $self->{drag_start_x} =
                    $event->x;

                $self->{drag_initial_offset}
                    = $self->{offset};
            }
        );

        # =====================================================
        # DRAG MOVE
        # =====================================================

        $canvas->CanvasBind(

            '<B1-Motion>' => sub {

                my $event = $Tk::event;

                $self->drag_chart(
                    $event->x
                );
            }
        );

        # =====================================================
        # DRAG END
        # =====================================================

        $canvas->CanvasBind(

            '<ButtonRelease-1>' => sub {

                $self->{dragging} = 0;
            }
        );

        # =====================================================
        # MOUSE MOVE
        # =====================================================

        $canvas->CanvasBind(

            '<Motion>' => sub {

                my $event = $Tk::event;

                $self->{mouse_x} =
                    $event->x;

                $self->{mouse_y} =
                    $event->y;

                $self->draw_crosshair();
            }
        );

        # =====================================================
        # LEAVE
        # =====================================================

        $canvas->CanvasBind(

            '<Leave>' => sub {

                $self->{mouse_x} = undef;

                $self->{mouse_y} = undef;

                $self->{crosshair_index}
                    = undef;

                $self->draw_crosshair();
            }
        );
    }

    # =====================================================
    # KEYBOARD SHORTCUTS (price canvas)
    # =====================================================

    my $pc = $self->{price_canvas};

    $pc->CanvasBind(
        '<Key-1>' => sub {
            $self->set_timeframe(1);
        }
    );

    $pc->CanvasBind(
        '<Key-5>' => sub {
            $self->set_timeframe(5);
        }
    );

    $pc->CanvasBind(
        '<Key-6>' => sub {
            $self->set_timeframe(15);
        }
    );
}

# =========================================================
# TIMEFRAME
# =========================================================

sub set_timeframe {
    my ($self, $minutes) = @_;

    return
        if $minutes
        == $self->{market_data}->get_timeframe();

    $self->{market_data}->set_timeframe(
        $minutes
    );

    $self->{offset} = 0;

    $self->{visible_bars} = 120;

    $self->{indicator_manager}->update_all();

    $self->render_full();
}

# =========================================================
# HORIZONTAL ZOOM
# =========================================================

sub zoom_in {
    my ($self, $mouse_x) = @_;

    my $old = $self->{visible_bars};
    my $new = int($old * 0.85);

    $new = $self->{min_visible_bars}
        if $new < $self->{min_visible_bars};

    $self->_apply_zoom($old, $new, $mouse_x);

    $self->render_incremental();
}

sub zoom_out {
    my ($self, $mouse_x) = @_;

    my $old = $self->{visible_bars};
    my $new = int($old * 1.15);

    $new = $self->{max_visible_bars}
        if $new > $self->{max_visible_bars};

    $self->_apply_zoom($old, $new, $mouse_x);

    $self->render_incremental();
}

sub _apply_zoom {
    my ($self, $old_visible, $new_visible, $mouse_x) = @_;

    if (defined $mouse_x && $mouse_x >= 0) {

        my $price_width =
            $self->{price_canvas}->Width;

        my $chart_width =
            $price_width
            - $self->{right_axis_width};

        if (
            $chart_width > 0
            && $old_visible > 0
        ) {

            my $fraction =
                $mouse_x / $chart_width;

            $fraction = 0
                if $fraction < 0;

            $fraction = 1
                if $fraction > 1;

            my $bar_under_mouse =
                $self->{offset}
                + $fraction * $old_visible;

            my $new_offset = int(
                $bar_under_mouse
                - $fraction * $new_visible
            );

            $new_offset = 0
                if $new_offset < 0;

            my $max_offset =
                $self->{market_data}->size()
                - $new_visible;

            $max_offset = 0
                if $max_offset < 0;

            $self->{offset} = $new_offset
                if $new_offset <= $max_offset;

            $self->{offset} = $max_offset
                if $self->{offset} > $max_offset;
        }
    }

    $self->{visible_bars} = $new_visible;
}

# =========================================================
# VERTICAL ZOOM
# =========================================================

sub zoom_vertical_in {
    my ($self) = @_;

    $self->{vertical_zoom} /= 1.15;

    $self->{vertical_zoom}
        = $self->{min_vertical_zoom}
        if $self->{vertical_zoom}
        < $self->{min_vertical_zoom};

    $self->render_incremental();
}

sub zoom_vertical_out {
    my ($self) = @_;

    $self->{vertical_zoom} *= 1.15;

    $self->{vertical_zoom}
        = $self->{max_vertical_zoom}
        if $self->{vertical_zoom}
        > $self->{max_vertical_zoom};

    $self->render_incremental();
}

# =========================================================
# DRAG
# =========================================================

sub drag_chart {
    my ($self, $current_x) = @_;

    return unless $self->{dragging};

    my $dx =
        $current_x
        - $self->{drag_start_x};

    my $bars_moved =
        int($dx / 8);

    $self->{offset}
        = $self->{drag_initial_offset}
        - $bars_moved;

    $self->{offset} = 0
        if $self->{offset} < 0;

    my $max_offset =
        $self->{market_data}->size()
        - $self->{visible_bars};

    $max_offset = 0
        if $max_offset < 0;

    $self->{offset}
        = $max_offset
        if $self->{offset} > $max_offset;

    $self->render_incremental();
}

# =========================================================
# COMPUTE WINDOW
# =========================================================

sub compute_window {
    my ($self) = @_;

    my $total =
        $self->{market_data}->size();

    my $start =
        $self->{offset};

    my $end =
        $start
        + $self->{visible_bars};

    $end = $total - 1
        if $end >= $total;

    return ($start, $end);
}

# =========================================================
# FULL RENDER
# =========================================================

sub render_full {
    my ($self) = @_;

    $self->{_needs_static_redraw} = 1;

    $self->render_incremental();
}

# =========================================================
# REQUEST RENDER (from resize)
# =========================================================

sub request_render {
    my ($self) = @_;

    $self->render_full();
}

# =========================================================
# RENDER INCREMENTAL
# =========================================================

sub render_incremental {
    my ($self) = @_;

    my ($start, $end)
        = $self->compute_window();

    my $data =
        $self->{market_data}
        ->get_slice($start, $end);

    return unless @$data;

    my $price_canvas =
        $self->{price_canvas};

    my $atr_canvas =
        $self->{atr_canvas};

    # =====================================================
    # DELETE APPROPRIATE TAGS
    # =====================================================

    if ($self->{_needs_static_redraw}) {

        $price_canvas->delete(
            'static_render',
            'price_render',
            'crosshair'
        );

        $atr_canvas->delete(
            'static_render',
            'atr_render',
            'crosshair'
        );

        $self->{_needs_static_redraw} = 0;

    } else {

        $price_canvas->delete(
            'price_render',
            'crosshair'
        );

        $atr_canvas->delete(
            'atr_render',
            'crosshair'
        );
    }

    # =====================================================
    # DIMENSIONS
    # =====================================================

    my $price_width =
        $price_canvas->Width;

    my $price_height =
        $price_canvas->Height;

    my $atr_height =
        $atr_canvas->Height;

    my $chart_width =
        $price_width
        - $self->{right_axis_width};

    my $chart_height =
        $price_height
        - $self->{bottom_axis_height};

    my $bar_width =
        $chart_width
        / $self->{visible_bars};

    # =====================================================
    # PRICE SCALE
    # =====================================================

    my ($min_price, $max_price)
        = $self->{price_panel}
        ->get_y_range($data);

    # apply vertical zoom
    my $center =
        ($min_price + $max_price) / 2;

    my $half_range =
        ($max_price - $min_price) / 2
        * $self->{vertical_zoom};

    $min_price =
        $center - $half_range;

    $max_price =
        $center + $half_range;

    my $price_scale =
        Market::Panels::Scales->new(

        width => $chart_width,

        height => $chart_height,

        min_value => $min_price,

        max_value => $max_price,

        bar_width => $bar_width,
    );

    # =====================================================
    # ATR SCALE
    # =====================================================

    my $atr_values =
        $self->{indicator_manager}
        ->slice_array(
            'atr',
            $start,
            $end
        );

    my ($min_atr, $max_atr)
        = $self->{atr_panel}
        ->get_y_range($atr_values);

    my $atr_scale =
        Market::Panels::Scales->new(

        width => $chart_width,

        height =>
            $atr_height
            - $self->{bottom_axis_height},

        min_value => $min_atr,

        max_value => $max_atr,

        bar_width => $bar_width,
    );

    # =====================================================
    # RENDER STATIC (full redraw only)
    # =====================================================

    if ($self->{_needs_static_redraw}) {

        $self->{price_panel}->render_static(

            $price_canvas,
            $self
        );

        $self->{atr_panel}->render_static(

            $atr_canvas,
            $self
        );
    }

    $self->{_needs_static_redraw} = 0;

    # =====================================================
    # RENDER DYNAMIC
    # =====================================================

    $self->{price_panel}->render_dynamic(

        $price_canvas,

        $data,

        $price_scale,

        $self
    );

    $self->{atr_panel}->render_dynamic(

        $atr_canvas,

        $atr_values,

        $atr_scale,

        $self
    );

    # =====================================================
    # STORE LAST STATE FOR CROSSHAIR
    # =====================================================

    $self->{_last_data} = $data;

    $self->{_last_atr_values} = $atr_values;

    $self->{_last_price_scale} = $price_scale;

    $self->{_last_atr_scale} = $atr_scale;

    $self->{_last_chart_width} = $chart_width;

    $self->{_last_chart_height} = $chart_height;

    $self->{_last_atr_height} = $atr_height;

    # =====================================================
    # CROSSHAIR
    # =====================================================

    $self->draw_crosshair();
}

# =========================================================
# DRAW CROSSHAIR
# =========================================================

sub draw_crosshair {
    my ($self) = @_;

    my $mx = $self->{mouse_x};
    my $my = $self->{mouse_y};

    my $price_canvas =
        $self->{price_canvas};

    my $atr_canvas =
        $self->{atr_canvas};

    # =====================================================
    # CLEAR OLD CROSSHAIR
    # =====================================================

    $price_canvas->delete('crosshair');

    $atr_canvas->delete('crosshair');

    return
        unless defined $mx;

    my $chart_width =
        $self->{_last_chart_width};

    my $chart_height =
        $self->{_last_chart_height};

    my $atr_height =
        $self->{_last_atr_height};

    return
        unless defined $chart_width;

    # =====================================================
    # PRICE CROSSHAIR LINES
    # =====================================================

    $price_canvas->createLine(

        $mx,
        0,
        $mx,
        $chart_height,

        -fill =>
            $self->{crosshair_color},

        -dash => '.',

        -tags => 'crosshair',
    );

    $price_canvas->createLine(

        0,
        $my,
        $chart_width,
        $my,

        -fill =>
            $self->{crosshair_color},

        -dash => '.',

        -tags => 'crosshair',
    );

    # =====================================================
    # ATR CROSSHAIR LINE
    # =====================================================

    $atr_canvas->createLine(

        $mx,
        0,
        $mx,
        $atr_height,

        -fill =>
            $self->{crosshair_color},

        -dash => '.',

        -tags => 'crosshair',
    );

    # =====================================================
    # PANEL CROSSHAIR LABELS
    # =====================================================

    $self->{price_panel}->render_crosshair_labels(

        $price_canvas,

        $self->{_last_data},

        $self->{_last_price_scale},

        $self,
    );

    $self->{atr_panel}->render_crosshair_labels(

        $atr_canvas,

        $self->{_last_atr_scale},

        $self,
    );
}

1;
