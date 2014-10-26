use strict;
use warnings;
use Test::More;
use Gnuplot::Builder::Dataset;

{
    note("--- example");
    my $dataset = Gnuplot::Builder::Dataset->new_file("hoge.dat");
    $dataset->set_join(using => ":", every => ":");
    $dataset->set(
        using => [1, '(($2 + $3)/2.0*1000)'],
        every => [1, 1, 1, 0],
        with  => ["linespoints", "ps 3", "lt 2"],
    );
    is $dataset->to_string, q{'hoge.dat' using 1:(($2 + $3)/2.0*1000) every 1:1:1:0 with linespoints ps 3 lt 2}, "example OK";
}

## test patterns:

fail("join: undef / string"); ## デフォルトのjoinはテスト済み。undef指定もテストは必要か？
fail("opt: not set / explicit undef / string / array-ref (empty, single, multi) / code-ref (empty, single, multi)");
fail("setq_opt: array-ref multi / code-ref multi"); ## これだけでいいでしょ・・・

fail("join inherit: set in child / set in parent / set in both / not set in either");
fail("join inherit: override with undef");
fail("delete_join: set in both -> delete_join() for child and parent");

done_testing;

