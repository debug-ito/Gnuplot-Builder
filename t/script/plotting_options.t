use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Identity;
use Gnuplot::Builder::Script;
use Gnuplot::Builder::Process;

$Gnuplot::Buidler::Process::NO_STDERR = 0;

{
    note('basic set-get-delete operation');
    my $s = Gnuplot::Builder::Script->new;
    is $s->get_plot('output'), undef;
    is $s->get_plot('no_stderr'), undef;
    identical $s->set_plot(output => "hoge.png"), $s;
    is $s->get_plot('output'), "hoge.png";
    is $s->get_plot('no_stderr'), undef;
    identical $s->set_plot(no_stderr => 1), $s;
    is $s->get_plot('output'), "hoge.png";
    is $s->get_plot('no_stderr'), 1;
    identical $s->delete_plot('output'), $s;
    is $s->get_plot('output'), undef;
    is $s->get_plot('no_stderr'), 1;
    identical $s->delete_plot('no_stderr'), $s;
    is $s->get_plot('output'), undef;
    is $s->get_plot('no_stderr'), undef;
}

{
    note('passing code-ref, get it as-is');
    my $s = Gnuplot::Builder::Script->new;
    my $code = sub { die "this should not be executed." };
    $s->set_plot(writer => $code);
    identical $s->get_plot("writer"), $code;
}

{
    note('passing array-ref, get it as-is');
    my $s = Gnuplot::Builder::Script->new;
    my $aref = [1, 2, 3];
    $s->set_plot(output => $aref);
    identical $s->get_plot("output"), $aref;
}



fail('effect on short-hands (plot() etc.)');

fail('override by given arguments');

fail('exception on unknown argument');

fail('inheritance set-get-delete');

done_testing;
