use strict;
use warnings;
use Test::More;
use Gnuplot::Builder::Process;
use Gnuplot::Builder::Script;
use Gnuplot::Builder::Dataset;
use Time::HiRes qw(sleep);

note("--- exception during plotting.");

sub wait_and_get_number_of_processes {
    sleep 0.5;
    Gnuplot::Builder::Script->new(term => "postscript")->plot("sin(x)"); ## to clear the died process.
    return Gnuplot::Builder::Process->FOR_TEST_process_num();
}

foreach my $case (
    {label => "from added sentence", plotset => sub {
        my $script = Gnuplot::Builder::Script->new;
        $script->add(sub { die "BOOM!" });
        return ($script, "sin(x)");
    }},
    {label => "from script option", plotset => sub {
        return (Gnuplot::Builder::Script->new(xrange => sub { die "BOOM!" }), "sin(x)");
    }},
    {label => "from script definition", plotset => sub {
        my $script = Gnuplot::Builder::Script->new;
        $script->define(a => sub { die "BOOM!" });
        return ($script, "sin(x)");
    }},
    {label => "from dataset source", plotset => sub {
        my $dataset = Gnuplot::Builder::Dataset->new(sub { die "BOOM!" });
        return (Gnuplot::Builder::Script->new, $dataset);
    }},
    {label => "from dataset option", plotset => sub {
        my $dataset = Gnuplot::Builder::Dataset->new("sin(x)", using => sub { die "BOOM!" });
        return (Gnuplot::Builder::Script->new, $dataset);
    }},
    {label => "from dataset inline data", plotset => sub {
        my $dataset = Gnuplot::Builder::Dataset->new_data(sub { die "BOOM!" });
        return (Gnuplot::Builder::Script->new, $dataset);
    }},
) {
    my ($script, @datasets) = $case->{plotset}->();
    local $@;
    eval {
        $script->plot(@datasets);
        fail("$case->{label}: it should die");
    };
    if($@) {
        pass("$case->{label}: died");
    }
    is(wait_and_get_number_of_processes, 0, "$case->{label}: no running process.");
}

{
    note("--- when writer for plot_with() dies.");
    local $@;
    my $script = Gnuplot::Builder::Script->new;
    eval {
        $script->plot_with(
            dataset => "sin(x)",
            writer => sub {
                die "BOOM!";
            }
        );
        fail("plot_with() should die");
    };
    if($@) {
        pass("plot_with() dies OK");
    }
}


note("--- exception from multiplot() and run()");
foreach my $case (
    {label => "multiplot", code => sub {
        my $builder = Gnuplot::Builder::Script->new;
        $builder->multiplot(sub { die "BOOM!" });
    }},
    {label => "run", code => sub {
        my $builder = Gnuplot::Builder::Script->new;
        $builder->run(sub { die "BOOM!" });
    }}
) {
    local $@;
    eval {
        $case->{code}->();
        fail("$case->{label}: it should die");
    };
    if($@) {
        pass "$case->{label}: died";
    }
    is(wait_and_get_number_of_processes, 0, "$case->{label}: no running process.");
}

done_testing;
