package Gnuplot::Builder::Util;
use strict;
use warnings;
use Exporter qw(import);
use Gnuplot::Builder::Version; our $VERSION = VERSION;

our @EXPORT_OK = qw(quote_gnuplot_str);

sub quote_gnuplot_str {
    my ($str) = @_;
    return undef if !defined($str);
    $str =~ s/'/''/g;
    return qq{'$str'};
}

1;
