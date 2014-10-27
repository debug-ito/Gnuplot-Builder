use strict;
use warnings FATAL => "all";
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

{
    note("--- set_option() test patterns");
    my @testcases = (
        {label => "join string, opt undef",
         join => ":", opt => undef, exp => ""},
        {label => "join string, opt string",
         join => ":", opt => "bar", exp => "foo bar"},
        {label => "join string, opt empty array",
         join => ":", opt => [], exp => ""},
        {label => "join string, opt single value array",
         join => ":", opt => ["bar"], exp => "foo bar"},
        {label => "join string, opt multi value array",
         join => ":", opt => ["bar", "buzz"], exp => "foo bar:buzz"},
        {label => "join undef, opt multi value array",
         join => undef, opt => ["bar", "buzz"], exp => "foo bar buzz"},
        {label => "join string, opt empty code",
         join => ":", opt => sub { () }, exp => ""},
        {label => "join string, opt single value code",
         join => ":", opt => sub { "bar" }, exp => "foo bar"},
        {label => "join string, opt multi value code",
         join => ":", opt => sub { ("bar", "buzz") }, exp => "foo bar:buzz"},
        {label => "join undef, opt multi value code",
         join => undef, opt => sub { ("bar", "buzz") }, exp => "foo bar buzz"}
    );
    foreach my $case (@testcases) {
        my $dataset = Gnuplot::Builder::Dataset->new;
        $dataset->set_join(foo => $case->{join});
        $dataset->set_option(foo => $case->{opt});
        is $dataset->to_string, $case->{exp}, "$case->{label}: OK";
    }
}

{
    note("--- setq_option() test patterns");
    my @testcases = (
        {label => "join string, opt multi value array",
         join => ":", opt => ["bar", "buzz"], exp => q{foo 'bar':'buzz'}},
        {label => "join undef, opt multi value array",
         join => undef, opt => ["bar", "buzz"], exp => q{foo 'bar' 'buzz'}},
        {label => "join string, opt multi value code",
         join => ":", opt => sub { ("bar", "buzz") }, exp => q{foo 'bar':'buzz'}},
        {label => "join undef, opt multi value code",
         join => undef, opt => sub { ("bar", "buzz") }, exp => q{foo 'bar' 'buzz'}},
    );
    foreach my $case (@testcases) {
        my $dataset = Gnuplot::Builder::Dataset->new;
        $dataset->set_join(foo => $case->{join});
        $dataset->setq_option(foo => $case->{opt});
        is $dataset->to_string, $case->{exp}, "$case->{label}: OK";
    }
}

{
    note("--- different join for different opt");
    my $dataset = Gnuplot::Builder::Dataset->new;
    $dataset->set_join(foo => '@@@', bar => '|');
    $dataset->set(foo => [qw(F O O)], bar => [qw(B A R)], buzz => [qw(B U Z Z)]);
    is $dataset->to_string, 'foo F@@@O@@@O bar B|A|R buzz B U Z Z';
}

done_testing;
