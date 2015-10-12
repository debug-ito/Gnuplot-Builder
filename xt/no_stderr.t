use strict;
use warnings FATAL => "all";
use Test::More;
use Gnuplot::Builder::Script;
use Gnuplot::Builder::Process;

$Gnuplot::Builder::Process::ASYNC = 0;

sub get_printed_string {
    my ($printed_string, $is_stderr) = @_;
    my $builder = Gnuplot::Builder::Script->new;
    my $target = $is_stderr ? "" : qq{'-'};
    $builder->add(qq{set print $target});
    $builder->add(qq{print "$printed_string"});
    return $builder->run;    
}

{
    local $Gnuplot::Builder::Process::NO_STDERR = 0;
    is get_printed_string("foobar", 0), "foobar\n";
    is get_printed_string("FOOBAR", 1), "FOOBAR\n";
}

{
    local $Gnuplot::Builder::Process::NO_STDERR = 1;
    is get_printed_string("hoge", 0), "hoge\n";
    is get_printed_string("HOGE", 1), "";
}

done_testing;
