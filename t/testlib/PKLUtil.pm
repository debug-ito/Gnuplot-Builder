package testlib::PKLUtil;
use strict;
use warnings;
use Exporter qw(import);
use Test::More;
use Test::Builder;

our @EXPORT_OK = qw(expect_pkl);

sub expect_pkl {
    my ($pkl, $exp, $msg) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $got = [];
    $pkl->each(sub {
        my ($key, $value) = @_;
        push(@$got, [$key, $value]);
    });
    is_deeply($got, $exp, $msg);
    foreach my $index (0 .. ($pkl->size - 1)) {
        is_deeply([$pkl->get_at($index)], $exp->[$index], "... get_at($index) OK");
    }
}

1;


