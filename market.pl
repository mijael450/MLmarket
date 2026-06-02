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

$engine->render();

# =========================================================
# MAIN LOOP
# =========================================================

MainLoop;