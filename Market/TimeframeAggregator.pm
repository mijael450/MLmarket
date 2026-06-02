package Market::TimeframeAggregator;

use strict;
use warnings;

sub aggregate {
    my ($class, $candles, $period_minutes) = @_;

    return $candles
        if $period_minutes <= 1;

    my %buckets;
    my @bucket_order;

    for my $candle (@$candles) {
        my $bucket_key =
            _bucket_key(
                $candle->{time},
                $period_minutes
            );

        if (exists $buckets{$bucket_key}) {

            my $b = $buckets{$bucket_key};

            $b->{high} = $candle->{high}
                if $candle->{high} > $b->{high};

            $b->{low} = $candle->{low}
                if $candle->{low} < $b->{low};

            $b->{close} = $candle->{close};

            $b->{volume} += $candle->{volume};

        } else {

            $buckets{$bucket_key} = {

                time   => $bucket_key,
                open   => $candle->{open},
                high   => $candle->{high},
                low    => $candle->{low},
                close  => $candle->{close},
                volume => $candle->{volume},
            };

            push @bucket_order, $bucket_key;
        }
    }

    my @aggregated;

    for my $key (@bucket_order) {

        push @aggregated,
            $buckets{$key};
    }

    return \@aggregated;
}

sub _bucket_key {
    my ($time, $period) = @_;

    if (
        $time
        =~ /^(\d{4}-\d{2}-\d{2}T)(\d{2}):(\d{2}):(\d{2})(.*)$/
    ) {

        my ($date, $hour, $min, $sec, $tz) =
            ($1, $2, $3, $4, $5);

        my $bucket_min =
            int($min / $period)
            * $period;

        return sprintf(
            "%s%02d:%02d:00%s",
            $date,
            $hour,
            $bucket_min,
            $tz
        );
    }

    return $time;
}

1;
