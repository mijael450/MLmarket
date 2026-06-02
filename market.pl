use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;

use Tk;

use Market::ChartEngine;
use Market::MarketData;
use Market::IndicatorManager;

# =========================================================
# LOAD MARKET DATA
# =========================================================

my $csv_file =
    shift || "$FindBin::Bin/2026_03.csv";

my $market_data =
    Market::MarketData->new(

        file => $csv_file,
    );

# =========================================================
# INDICATORS
# =========================================================

my $indicator_manager =
    Market::IndicatorManager->new(

        market_data =>
            $market_data,
    );

# =========================================================
# MAIN WINDOW
# =========================================================

my $mw = MainWindow->new;

$mw->title(
    'TradingView Style Market Chart'
);

$mw->geometry('1400x900');

$mw->configure(

    -bg => '#0f172a'
);

# =========================================================
# TIMEFRAME TOOLBAR
# =========================================================

my $toolbar =
    $mw->Frame(

        -bg => '#1e293b'
    )->pack(

        -side => 'top',

        -fill => 'x'
    );

my $tf_label = $toolbar->Label(

    -text => 'Timeframe: ',

    -fg => '#94a3b8',

    -bg => '#1e293b',

    -font => [
        'Arial',
        10
    ],
)->pack(

    -side => 'left',

    -padx => 5,

    -pady => 3
);

my $shortcut_label = $toolbar->Label(

    -text => '  |  Ctrl+Scroll=Zoom V  |  Drag=Scroll',

    -fg => '#64748b',

    -bg => '#1e293b',

    -font => [
        'Arial',
        9
    ],
)->pack(

    -side => 'left',

    -padx => 10,

    -pady => 3
);

# =========================================================
# MAIN CONTAINER
# =========================================================

my $container =
    $mw->Frame(

        -bg => '#0f172a'
    )->pack(

        -fill => 'both',

        -expand => 1
    );

# =========================================================
# PRICE PANEL
# =========================================================

my $price_canvas =
    $container->Canvas(

        -width  => 1400,

        -height => 650,

        -background => '#0f172a',

        -highlightthickness => 0,

        -takefocus => 1,
    )->pack(

        -side => 'top',

        -fill => 'both',

        -expand => 1
    );

# =========================================================
# ATR PANEL
# =========================================================

my $atr_canvas =
    $container->Canvas(

        -width  => 1400,

        -height => 220,

        -background => '#111827',

        -highlightthickness => 0,
    )->pack(

        -side => 'bottom',

        -fill => 'x'
    );

# =========================================================
# CHART ENGINE
# =========================================================

my $engine =
    Market::ChartEngine->new(

        market_data =>
            $market_data,

        indicator_manager =>
            $indicator_manager,

        price_canvas =>
            $price_canvas,

        atr_canvas =>
            $atr_canvas,
    );

# =========================================================
# TIMEFRAME DROPDOWN (after engine is created)
# =========================================================

my $tf_var = '1m';

my $tf_dropdown =
    $toolbar->Optionmenu(

        -options => [
            ['1m',  '1'],
            ['5m',  '5'],
            ['15m', '15'],
        ],

        -variable => \$tf_var,

        -command => sub {

            $engine->set_timeframe(
                $_[0] + 0
            );
        },

        -background => '#334155',

        -foreground => '#e2e8f0',

        -activebackground =>
            '#475569',

        -activeforeground =>
            '#ffffff',

        -font => [
            'Arial',
            9,
            'bold'
        ],

        -relief => 'flat',

        -borderwidth => 1,

        -highlightthickness => 0,

    )->pack(

        -side => 'left',

        -padx => 2,

        -pady => 3
    );

# =========================================================
# EVENTS
# =========================================================

$engine->bind_events();

# =========================================================
# RESIZE EVENTS
# =========================================================

$price_canvas->CanvasBind(

    '<Configure>' => sub {

        $engine->request_render();
    }
);

$atr_canvas->CanvasBind(

    '<Configure>' => sub {

        $engine->request_render();
    }
);

# =========================================================
# INITIAL RENDER
# =========================================================

$engine->render_full();

# =========================================================
# MAIN LOOP
# =========================================================

MainLoop;
