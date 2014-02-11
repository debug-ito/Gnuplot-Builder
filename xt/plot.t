use strict;
use warnings;
use Test::More;
use Test::Identity;
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
    identical $builder->plot("sin(2 * pi * x)"), $builder, "plot() method should return the object.";
    sleep 1;
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
    identical $builder->splot("sin(x*x + y*y) / (x*x + y*y)"), $builder, "splot() method should return the object";
    sleep 1;
    ok((-f $filename), "$filename output OK");
};

done_testing;


