use strict;
use warnings FATAL => "all";
use Test::More;
use Gnuplot::Builder::Template qw(gevery);

foreach my $case (
    {label => "empty", input => [], exp => "1"},
    {label => "point_incr", input => [-point_incr => 10], exp => "10"},
    {label => "block_incr", input => [-block_incr => 10], exp => "1:10"},
    {label => "start_point", input => [-start_point => 10], exp => "1::10"},
    {label => "start_block", input => [-start_block => 10], exp => "1:::10"},
    {label => "end_point", input => [-end_point => 10], exp => "1::::10"},
    {label => "end_block", input => [-end_block => 10], exp => "1:::::10"},
    {label => "split", input => [-block_incr => 10, -end_point => 20], exp => "1:10:::20"},
    {label => "custom", input => [hoge => 10], exp => "1::::::10"},
    {label => "undef point_incr", input => [-point_incr => undef], exp => ""},
    {label => "undef point_incr and custom", input => [-point_incr => undef, hoge => 10, foo => 20], exp => "10:20"},
) {
    my $every = gevery(@{$case->{input}});
    is "$every", $case->{exp}, "$case->{label}: OK";
}

{
    note("--- internal key check");
    my $every = gevery();
    my @keys = $every->get_all_keys;
    is scalar(grep { $_ !~ /^-/ } @keys), 0, "all predefined keys start with hyphen";
}

{
    note("--- unknown hyphen keys");
    like(
        exception { gevery(-start_point => 10, -this_does_not_exist => 20) },
        qr/unknown key.*-this_does_not_exist/i,
        "it dies if unknown hyphen keys are given"
    );
    my $every = gevery(-point_incr => 10);
    like(
        exception { $every->set(-this_does_not_exist => 200) },
        qr/unknown key.*-this_does_not_exist/i,
        "it dies if unknown hyphen keys are given, even after JoinDict is created"
    );
}


done_testing;
