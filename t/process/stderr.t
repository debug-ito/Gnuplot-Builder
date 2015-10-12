use strict;
use warnings FATAL => "all";
use lib "t";
use testlib::ScriptUtil qw(plot_str);
use Test::More;
use Gnuplot::Builder::Script;
use Gnuplot::Builder::Dataset;

sub create_builder {
    my ($no_stderr) = @_;
    my $builder = Gnuplot::Builder::Script->new(
        terminal => 'dumb',
    );
    $builder->set_no_stderr($no_stderr);
    return $builder;
}

{
    my $builder = create_builder(0);
    my $dataset = Gnuplot::Builder::Dataset->new_data(
        sub {
            my ( $dataset, $writer ) = @_;

            for ( 1 .. 10 ) {
                $writer->("$_ 10\n");
            }
        },
        with  => "lines",
        title => "'xyz'",
    );
    my $ret_err = $builder->plot($dataset);
    like ($ret_err, qr/Warning/, "Test for stderr-output");
}

{
    my $builder = create_builder(1);
    my $dataset = Gnuplot::Builder::Dataset->new_data(
        sub {
            my ( $dataset, $writer ) = @_;

            for ( 1 .. 10 ) {
                $writer->("$_ 10\n");
            }
        },
        with  => "lines",
        title => "'xyz'",
    );
    my $ret_noerr = $builder->plot($dataset);
    unlike ($ret_noerr, qr/Warning/, "Test for no stderr-output");
}
done_testing;
