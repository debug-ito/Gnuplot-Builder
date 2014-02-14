use strict;
use warnings;
use Test::More;
use Gnuplot::Builder::Script;

sub if_no_file {
    my ($filename, $code) = @_;
  SKIP: {
        if(-f $filename) {
            skip "File $filename exists. Remove it first.", 1;
        }
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
    is $builder->splot("sin(x*x + y*y) / (x*x + y*y)"), $builder, "gnuplot process should output nothing";
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

done_testing;
