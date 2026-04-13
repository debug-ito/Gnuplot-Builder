use strict;
use warnings;
use Test::More;
use Gnuplot::Builder::Script;
use Gnuplot::Builder::Process;

foreach my $exit_status (0, 1, 100) {
    my $s = Gnuplot::Builder::Script->new(
        terminal => "svg",
    );
    $s->add("exit $exit_status");
    my $got_status;
    $s->plot_with(
        dataset => 'sin(x)',
        on_exit => sub {
            my ($status) = @_;
            $got_status = $status;
        },
    );
    Gnuplot::Builder::Process->wait_all;
    is($got_status, ($exit_status << 8), "exit_status = $exit_status");
}

done_testing;
