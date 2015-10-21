package Gnuplot::Builder::Lens;
use strict;
use warnings;

1;




__END__

=pod

=head1 NAME

Gnuplot::Builder::Lens - a lens for Gnuplot::Builder objects

=head1 SYNOPSIS

    use Data::Focus qw(focus);
    use Gnuplot::Builder::Lens qw(gopt);
    use Gnuplot::Builder::Script;
    
    my $term_lens = gopt("term");
    
    my $s = Gnuplot::Builder::Script->new;
    focus($s)->set($term_lens, "png size 800,700");
    
    focus($s)->get($term_lens);  ## => "png size 800,700"


=head1 DESCRIPTION

This module provides constructors for L<Data::Focus::Lens> implementations.
You can use these lenses for accessing attributes of L<Gnuplot::Builder::Script>,
L<Gnuplot::Builder::Dataset> and L<Gnuplot::Builder::JoinDict>.

=head1 EXPORTABLE FUNCTIONS

These functions are exported only by request.

=head2 $lens = gopt($key)

Create a C<$lens> for an option named C<$key>. This lens uses C<get_option()> and C<set_option()> methods.

    my $lens = gopt("term");
    focus($script)->get($lens);        ## $script->get_option("term")
    focus($script)->set($lens, "x11"); ## $script->set_option("term" => "x11")

You can use this C<$lens> with L<Gnuplot::Builder::Script> and L<Gnuplot::Builder::Dataset> objects.


=head2 $lens = gdef($key)

=head2 $lens = gkey($key)

=head1 SEE ALSO

L<Data::Focus>

=head1 AUTHOR

Toshio Ito, C<< toshioito at cpan.org >>

=cut
