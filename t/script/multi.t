use strict;
use warnings;
use Test::More;
use Gnuplot::Builder::Script;

my @test_cases = (
    {
        label => "example: direct write",
        args => {
            option => 'layout 2,1',
            do => sub {
                my $writer = shift;
                $writer->("plot sin(x)\n");
                $writer->("plot cos(x)\n");
            }
        },
        exp => <<'EXP'
set multiplot layout 2,1
plot sin(x)
plot cos(x)
unset multiplot
EXP
    },
    {
        label => "example: mix direct and another builder",
        args => {
            do => sub {
                my $writer = shift;
                my $another_builder = Gnuplot::Builder::Script->new;
                $another_builder->plot("sin(x)"); ## This is the same as below
                $another_builder->plot_with(
                    dataset => "sin(x)",
                    writer => $writer
                );
            }
        },
        exp => <<'EXP'
set multiplot
plot sin(x)
plot sin(x)
unset multiplot
EXP
    },
    {
        label => "with output",
        args => {
            output => "hoge.eps",
            do => sub { $_[0]->("plot sin(x)\n") },
        },
        exp => <<'EXP'
set output 'hoge.eps'
set multiplot
plot sin(x)
unset multiplot
set output
EXP
    },
    {
        label => "the code not calling writer",
        args => {
            option => "title 'test'",
            do => sub {  }
        },
        exp => <<'EXP'
set multiplot title 'test'
unset multiplot
EXP
    },
    {
        label => "async has no effect if writer is present",
        args => {
            option => "layout 3,1",
            async => 1,
            do => sub {
                Gnuplot::Builder::Script->new->plot("sin(x)", "cos(x)");
            }
        },
        exp => <<'EXP'
set multiplot layout 3,1
plot sin(x),cos(x)
unset multiplot
EXP
    },
    {
        label => "code data without trailing newline",
        args => {
            do => sub {
                my $writer = shift;
                $writer->("set ");
                $writer->("termi");
                $writer->("nal png");
            }
        },
        exp => <<'EXP'
set multiplot
set terminal png
unset multiplot
EXP
    }
);

fail("code calling writer with empty data");


foreach my $case (@test_cases) {
    my $builder = Gnuplot::Builder::Script->new;
    my $got = "";
    my $result = $builder->multiplot_with(
        %{$case->{args}},
        writer => sub { $got .= $_[0] }
    );
    is $got, $case->{exp}, "$case->{label}: multiplot_with() OK";
    is $result, "", "$case->{label}: multiplot_with() should return an empty string if writer is present.";
}



{
    note("--- example: multiplot from non-empty Script.");
    my $builder = Gnuplot::Builder::Script->new;
    $builder->set(mxtics => 5, mytics => 5, term => "png");
    
    my $script = "";
    $builder->multiplot_with(
        output => "multi.png",
        writer => sub { $script .= $_[0] },
        option => 'title "multiplot test" layout 2,1',
        do => sub {
            my $another_builder = Gnuplot::Builder::Script->new;
            $another_builder->setq(title => "sin")->plot("sin(x)");
            $aonther_builder->setq(title => "cos")->plot("cos(x)");
        }
    );
    is $script, <<'EXP', "result OK";
set mxtics 5
set mytics 5
set term png
set output 'multi.png'
set multiplot title "multiplot test" layout 2,1
set title 'sin'
plot sin(x)
set title 'cos'
plot cos(x)
unset multiplot
set output
EXP
}


fail("maybe xt: multiplot() with 1 arg and 2 args");
fail("xt: multiplot() return error message if something is wrong. If async, there's no error message");

done_testing;
