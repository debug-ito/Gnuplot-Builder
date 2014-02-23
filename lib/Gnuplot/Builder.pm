package Gnuplot::Builder;
use strict;
use warnings;
use Gnuplot::Builder::Version; our $VERSION = VERSION;


1;
__END__

=pod

=head1 NAME

Gnuplot::Builder - object-oriented gnuplot script builder

=head1 DESCRIPTION

B<< This is an alpha release. API may change in the future. >>

L<Gnuplot::Builder> is a gnuplot script builder with the following charactestics.

=over

=item *

B<Object-oriented>. Script settings are encapsulated in a L<Gnuplot::Builder::Script> object,
and dataset parameters are in a L<Gnuplot::Builder::Dataset> object.

=item *

B<Thin>. L<Gnuplot::Builder> just builds script texts and streams to a gnuplot process.
Its behavior is extremely predictable and easy to debug.

=item *

B<Hierarchical>. L<Gnuplot::Builder::Script> and L<Gnuplot::Builder::Dataset> objects support
prototype-based inheritance, just like JavaScript objects.
This is useful for hierarchical configuration.

=back

Currently, L<Gnuplot::Builder> does not have any useful code.
Use L<Gnuplot::Builder::Script> and L<Gnuplot::Builder::Dataset>.


=head1 REPOSITORY

L<https://github.com/debug-ito/Gnuplot-Builder>

=head1 BUGS AND FEATURE REQUESTS

Please report bugs and feature requests to my Github issues
L<https://github.com/debug-ito/Gnuplot-Builder/issues>.

Although I prefer Github, non-Github users can use CPAN RT
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Gnuplot-Builder>.
Please send email to C<bug-Gnuplot-Builder at rt.cpan.org> to report bugs
if you do not have CPAN RT account.


=head1 AUTHOR
 
Toshio Ito, C<< <toshioito at cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Toshio Ito.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

