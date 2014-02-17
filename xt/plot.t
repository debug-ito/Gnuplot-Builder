use strict;
use warnings;
use Test::More;
use Gnuplot::Builder::Script;
use Time::HiRes qw(time);

sub if_no_file {
    my ($filename, $code) = @_;
  SKIP: {
        if(-f $filename) {
            skip "File $filename exists. Remove it first.", 1;
        }
        note("--- output $filename");
        $code->($filename);
    }
}

if_no_file "test_plot.png", sub {
    my $filename = shift;
    my $builder = Gnuplot::Builder::Script->new;
    $builder->set(<<SET);
term   = png size 500,500
xrange = [-2:2]
yrange = [-1:1]
xlabel = "x label"
ylabel = "y label"
SET
    $builder->setq(output => $filename);
    is $builder->plot("sin(2 * pi * x)"), "", "gnuplot process should output nothing.";
    ok((-f $filename), "$filename output OK");
};

if_no_file "test_splot.png", sub {
    my $filename = shift;
    my $builder = Gnuplot::Builder::Script->new;
    $builder->set(<<SET);
term   = png size 500,500
xrange = [-2:2]
yrange = [-2:2]
zrange = [-1:1]
xlabel = "x label"
ylabel = "y label"
zlabel = "z label"
SET
    $builder->setq(output => $filename);
    is $builder->splot("sin(x*x + y*y) / (x*x + y*y)"), "", "gnuplot process should output nothing";
    ok((-f $filename), "$filename output OK");
};

if_no_file "test_error.png", sub {
    my $filename = shift;
    my $builder = Gnuplot::Builder::Script->new;
    $builder->add("hohwa afafaw  adfhas asefhas");
    $builder->add("asha arasaf h a");
    $builder->set(term => "png size 200,200");
    $builder->setq(output => $filename);
    my $result = $builder->plot("sin(x)");
    isnt $result, "", "gnuplot process should output some error messages";
    note("gnuplot error message: $result");
};

if_no_file "test_print.png", sub {
    my $filename = shift;
    my $builder = Gnuplot::Builder::Script->new;
    $builder->add(qq{print "hoge hoge"});
    $builder->add(qq{print "foo bar"});
    $builder->set(term => "png size 700,500");
    $builder->setq(output => $filename, title => "print test");
    is $builder->plot("cos(x)"), <<EXP, "gnuplot process output by print command OK";
hoge hoge
foo bar
EXP
};

foreach my $term (
    $^O eq 'MSWin32' ? ("windows", "wxt") : ("x11", "wxt")
) {
    my $builder = Gnuplot::Builder::Script->new(term => "$term");
    {
        note("--- $term terminal: no error");
        my $before_time = time;
        is $builder->plot("cos(x)"), "", "$term: gnuplot process should output nothing";
        my $wait_time = time - $before_time;
        cmp_ok $wait_time, "<", 1, "$term: plot() should return immediately";
    }
    {
        note("--- $term terminal: with error");
        my $result = $builder->plot('sin(x) ps 4 with lp title "FOOBAR"');
        isnt $result, "", "$term: gnuplot process should output some error messages";
        note("$term: gnuplot error message: $result");
    }
}

done_testing;
