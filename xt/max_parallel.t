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

is $Gnuplot::Builder::Process::MAX_PROCESSES, 10, "by default, max is 10";

$Gnuplot::Builder::Process::MAX_PROCESSES = 3;

my $builder = Gnuplot::Builder::Script->new(
    term => "postscript eps",
);
$builder->add("pause 3");

cmp_ok plot_time($builder), "<", "1", "1st plot: no time";
cmp_ok plot_time($builder), "<", "1", "2st plot: no time";
cmp_ok plot_time($builder), "<", "1", "3st plot: no time";
cmp_ok plot_time($builder), ">", "2", "4th plot: wait until any of the previous ones";

done_testing;
