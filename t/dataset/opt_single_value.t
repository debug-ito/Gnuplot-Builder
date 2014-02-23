use strict;
use warnings;
use Test::More;
use Test::Identity;
use Gnuplot::Builder::Dataset;

foreach my $case (
    {method => 'set_option', label => "undef", val => undef,
     exp_str => "f(x)", exp_get => undef},
    {method => 'set_option', label => "string", val => "bar",
     exp_str => "f(x) foo bar", exp_get => "bar"},
    {method => 'set_option', label => "empty string", val => "",
     exp_str => 'f(x) foo', exp_get => ''},
    {method => 'set_option', label => "code", val => sub { "BAR" },
     exp_str => "f(x) foo BAR", exp_get => "BAR"},
    {method => 'set_option', label => "code returning undef", val => sub { (undef, "BAR") },
     exp_str => 'f(x)', exp_get => undef},
    {method => 'setq_option', label => "undef", val => undef,
     exp_str => "f(x)", exp_get => undef},
    {method => 'setq_option', label => "string", val => "bar",
     exp_str => "f(x) foo 'bar'", exp_get => q{'bar'}},
    {method => 'setq_option', label => "empty string", val => "",
     exp_str => "f(x) foo ''", exp_get => q{''}},
    {method => 'setq_option', label => "code", val => sub { "BAR" },
     exp_str => "f(x) foo 'BAR'", exp_get => q{'BAR'}},
    {method => 'setq_option', label => "code returning undef", val => sub { (undef, "BAR") },
     exp_str => 'f(x)', exp_get => undef},

) {
    my $label = "$case->{method} $case->{label}";
    my $method = $case->{method};
    my $dataset = Gnuplot::Builder::Dataset->new('f(x)');
    identical $dataset->$method(foo => $case->{val}), $dataset, "$label: $method() returns the dataset";
    is $dataset->to_string, $case->{exp_str}, "$label: to_string() OK";
    is $dataset->get_option("foo"), $case->{exp_get}, "$label: get_option() OK";
}

{
    note('--- code-ref values');
    foreach my $case (
        {method => "set_option", exp => q{buzz}},
        {method => "setq_option", exp => q{'buzz'}},
    ) {
        my $method = $case->{method};
        my $dataset = Gnuplot::Builder::Dataset->new('f(x)');
        my $called = 0;
        $dataset->$method(fizz => sub {
            my ($inner_dataset, $opt_name) = @_;
            identical $inner_dataset, $dataset, "inner dataset OK";
            is $opt_name, "fizz", "opt name OK";
            ok wantarray, "list context OK";
            $called++;
            return ("buzz", "hoge");
        });
        is $called, 0, "$method: not called yet";
        is $dataset->to_string, "f(x) fizz $case->{exp}", "$method: result OK";
        is $called, 1, "$method: called once";
        $called = 0;

        is $dataset->get_option("fizz"), $case->{exp}, "$method: get_option() OK";
        is $called, 1, "$method: called once";
        $called = 0;
    }
}

done_testing;