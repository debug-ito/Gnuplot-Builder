package Gnuplot::Builder::Template;
use strict;
use warnings;

1;
__END__

=pod

=head1 NAME

Gnuplot::Builder::Template - predefined Gnuplot::Builder objects as templates

=head1 SYNOPSIS

    use Gnuplot::Builder::Dataset;
    use Gnuplot::Builder::Template qw(using every);
    
    my $dataset = Gnuplot::Builder::Dataset->new_data("sample.dat");
    $dataset->set(
        using => using(
            x => 1, xlow => 2, xhigh => 3,
            y => 4, ylow => 5, yhigh => 6
        ),
        every => every(
            start_point => 1, end_point => 50
        ),
        with => "xyerrorbars",
    );
    "$dataset";  ## => 'sample.dat' using 1:4:2:3:5:6 every ::1:50 with xyerrorbars
    
    $dataset->get_option("using")->get("xlow");         ## => 2
    $dataset->get_option("every")->get("start_point");  ## => 1

=head1 DESCRIPTION

TODO: write description

=head1 EXPORTABLE FUNCTIONS

The following functions are exported only by request.

=head2 $using_joindict = using(%params)

=head2 $every_joindict = every(%params)

=head1 AUTHOR

Toshio Ito, C<< <toshioito at cpan.org> >>

=cut
