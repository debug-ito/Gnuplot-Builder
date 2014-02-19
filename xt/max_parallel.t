use strict;
use warnings;
use Test::More;
use Gnuplot::Builder::Script;
use Gnuplot::Builder::Process;
use Time::HiRes qw(time);

sub plot_time {
    my $builder = shift;
    my $before = time;
    is $builder->plot_with(dataset => "sin(x)", async => 1), "",
        "async plot always returns an empty string";
    return time() - $before;
}

sub process_num { Gnuplot::Builder::Process::FOR_TEST_process_num }

is $Gnuplot::Builder::Process::MAX_PROCESSES, 10, "by default, max is 10";

{
    note("--- limit max processes");
    local $Gnuplot::Builder::Process::MAX_PROCESSES = 3;
    my $builder = Gnuplot::Builder::Script->new(
        term => "postscript eps",
    );
    $builder->add("pause 3");

    cmp_ok plot_time($builder), "<", 1, "1st plot: no time";
    cmp_ok plot_time($builder), "<", 1, "2st plot: no time";
    cmp_ok plot_time($builder), "<", 1, "3st plot: no time";
    is process_num(), 3, "3 processes running";
    cmp_ok plot_time($builder), ">", 2, "4th plot: wait until one of the previous ones";
}

sleep 4;

{
    note("--- no limit");
    local $Gnuplot::Builder::Process::MAX_PROCESSES = 0;
    my $builder = Gnuplot::Builder::Script->new(
        term => "postscript eps"
    );
    $builder->add("pause 1");
    foreach my $round (1..10) {
        cmp_ok plot_time($builder), "<", 1, "round $round: no time";
    }
    is process_num(), 10, "10 processes running";
    sleep 2;
    cmp_ok plot_time($builder), "<", 1, "last round: no time";
    is process_num(), 1, "1 process running";
}


done_testing;
