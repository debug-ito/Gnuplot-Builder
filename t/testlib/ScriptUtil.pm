package testlib::ScriptUtil;
use strict;
use warnings;
use Test::Identity;
use Test::Builder;
use Exporter qw(import);

our @EXPORT_OK = qw(plot_str);

sub plot_str {
    my ($builder, $method, %args) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $result = "";
    $args{writer} = sub {
        my $part = shift;
        $result .= $part;
    };
    identical $builder->$method(%args), $builder, "$method should return the object.";
    return $result;
}

1;

