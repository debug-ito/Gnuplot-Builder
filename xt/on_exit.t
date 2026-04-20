use strict;
use warnings;
use Test::More;
use Gnuplot::Builder::Script;
use Gnuplot::Builder::Process;

note("--- plot and splot");

{
    my @cases = (
        {
            method => "plot_with",
            dataset => "sin(x)",
        },
        {
            method => "splot_with",
            dataset => "sin(x) * sin(y)",
        },
    );
    foreach my $output ("none", "test_on_exit_plot_splot.svg") {
        foreach my $case (@cases) {
            foreach my $exit_status (0, 1, 100) {
                my $method = $case->{method};
                my $label = "method = $method, output = $output, status = $exit_status";
                my $s = Gnuplot::Builder::Script->new(
                    terminal => "svg",
                );
                $s->add("exit status $exit_status");
                my $got_status;
                $s->$method(
                    dataset => $case->{dataset},
                    on_exit => sub {
                        my ($status) = @_;
                        $got_status = $status;
                    },
                    output => $output eq "none" ? undef : $output,
                );
                Gnuplot::Builder::Process->wait_all;
                is($got_status, ($exit_status << 8), $label);
            }
        }
    }
}

note('--- multiplot');

foreach my $output ("none", "text_on_exit_multiplot.svg") {
    foreach my $exit_status (0, 1, 100) {
        my $label = "method = multiplot_with, output = $output, status = $exit_status";
        my $s = Gnuplot::Builder::Script->new(
            terminal => "svg",
        );
        my $got_status;
        $s->multiplot_with(
            output => $output eq "none" ? undef : $output,
            on_exit => sub {
                my ($status) = @_;
                $got_status = $status;
            },
            do => sub {
                my ($writer) = @_;
                $writer->("exit status $exit_status\n");
            },
        );
        Gnuplot::Builder::Process->wait_all;
        is($got_status, ($exit_status << 8), $label);
    }
}


done_testing;
