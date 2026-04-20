use strict;
use warnings;
use Test::More;
use Gnuplot::Builder::Script;
use Gnuplot::Builder::Process;

note("--- plot and splot");

sub add_case_param {
    my ($param_name, $param_vals, @rest) = @_;
    return map {
        my $c = $_;
        map { +{%$c, $param_name => $_} } @$param_vals
    } @rest;
}

{
    my @cases = add_case_param(
        "exit_status", [0, 1, 100],
        map {
            (
                {%$_, method => "plot_with", dataset => "sin(x)"},
                {%$_, method => "splot_with", dataset => "sin(x) * sin(y)"},
            )
        } (add_case_param(
            "output", ["none", "test_on_exit_plot_splot.svg"], add_case_param(
            "async", [0, 1], {})
        ))
    );
    foreach my $case (@cases) {
        my $method = $case->{method};
        my $output = $case->{output};
        my $exit_status = $case->{exit_status};
        my $label = "method = $method, output = $output, async = $case->{async}, status = $exit_status";
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
            async => $case->{async},
        );
        Gnuplot::Builder::Process->wait_all;
        is($got_status, ($exit_status << 8), $label);
    }
}

note('--- multiplot and run');

{
    my @cases = add_case_param(
        "exit_status", [0, 1, 100], add_case_param(
        "output", ["none", "test_on_exit_multiplot_run.svg"], add_case_param(
        "async", [0, 1], add_case_param(
        "method",  ["multiplot_with", "run_with"], {}
    ))));
    foreach my $case (@cases) {
        my $method = $case->{method};
        my $output = $case->{output};
        my $exit_status = $case->{exit_status};
        my $label = "method = $method, output = $output, async = $case->{async}, status = $exit_status";
        my $s = Gnuplot::Builder::Script->new(
            terminal => "svg",
        );
        my $got_status;
        $s->$method(
            output => $output eq "none" ? undef : $output,
            async => $case->{async},
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
