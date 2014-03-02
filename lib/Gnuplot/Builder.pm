package Gnuplot::Builder;
use strict;
use warnings;
use parent qw(Exporter);
use Gnuplot::Builder::Script;
use Gnuplot::Builder::Dataset;
use Gnuplot::Builder::Process;

our $VERSION = "0.13";

our @EXPORT = our @EXPORT_OK = qw(gscript gfunc gfile gdata ghelp);

sub gscript {
    return Gnuplot::Builder::Script->new(@_);
}

sub gfunc {
    return Gnuplot::Builder::Dataset->new(@_);
}

sub gfile {
    return Gnuplot::Builder::Dataset->new_file(@_);
}

sub gdata {
    return Gnuplot::Builder::Dataset->new_data(@_);
}

sub ghelp {
    my (@help_args) = @_;
    my $process = Gnuplot::Builder::Process->new(capture => 1);
    my $terminator_guard = $process->terminator_guard;
    my $writer = $process->writer;
    $writer->("help");
    foreach my $arg (@help_args) {
        $writer->(" $arg");
    }
    $writer->("\n");
    undef $writer;
    $process->wait_to_finish;
    my $result = $process->result;
    $terminator_guard->cancel;
    return $result;
}

1;
__END__

=pod

=head1 NAME

Gnuplot::Builder - object-oriented gnuplot script builder

=head1 SYNOPSIS

    use Gnuplot::Builder;
    
    my $script = gscript(grid => "y", mxtics => 5, mytics => 5);
    $script->setq(
        xlabel => 'x values',
        ylabel => 'y values',
        title  => 'my plot'
    );
    $script->define('f(x)' => 'sin(x) / x');
    
    $script->plot(
        gfile('result.dat',
              using => '1:2:3', title => "'Measured'", with => "yerrorbars"),
        gfunc('f(x)', title => "'Theoretical'", with => "lines")
    );


=head1 DESCRIPTION

B<< This is a beta release. API may change in the future. >>

L<Gnuplot::Builder> is a gnuplot script builder. Its advantages include:

=over

=item *

B<Object-oriented>. Script settings are encapsulated in a L<Gnuplot::Builder::Script> object,
and dataset parameters are in a L<Gnuplot::Builder::Dataset> object.
It eliminates global variables, which gnuplot uses extensively.

=item *

B<Thin>. L<Gnuplot::Builder> just builds a script text and streams it into a gnuplot process.
Its behavior is extremely predictable and easy to debug.

=item *

B<Hierarchical>. L<Gnuplot::Builder::Script> and L<Gnuplot::Builder::Dataset> objects support
prototype-based inheritance, just like JavaScript objects.
This is useful for hierarchical configuration.

=item *

B<Interactive>. L<Gnuplot::Builder> works well both in batch scripts and in interactive shells.
Use L<Devel::REPL> or L<Reply> or whatever you like instead of the plain old gnuplot interative shell.

=back

=head1 USAGE GUIDE

L<Gnuplot::Builder> module is meant to be used in interactive shells.
It exports some easy-to-type functions by default.

For batch scripts, I recommend using L<Gnuplot::Builder::Script> and L<Gnuplot::Builder::Dataset> directly.
These modules are purely object-oriented, and won't mess up your namespace.


=head1 EXPORTED FUNCTIONS

L<Gnuplot::Builder> exports the following functions by default.

=head2 $script = gscript(@script_options)

Create a script object. It's just an alias for C<< Gnuplot::Builder::Script->new(...) >>.
See L<Gnuplot::Builder::Script> for detail.

=head2 $dataset = gfunc($funcion_spec, @dataset_options)

Create a dataset object representing a function, such as "sin(x)" and "f(x)".
It's just an alias for C<< Gnuplot::Builder::Dataset->new(...) >>.
See L<Gnuplot::Builder::Dataset> for detail.

=head2 $dataset = gfile($filename, @dataset_options)

Create a dataset object representing a data file.
It's just an alias for C<< Gnuplot::Builder::Dataset->new_file(...) >>.
See L<Gnuplot::Builder::Dataset> for detail.

=head2 $dataset = gdata($inline_data, @dataset_options)

Create a dataset object representing a data file.
It's just an alias for C<< Gnuplot::Builder::Dataset->new_data(...) >>.
See L<Gnuplot::Builder::Dataset> for detail.

=head2 $help_message = ghelp(@help_args)

Run the gnuplot "help" command and return the help message.
C<@help_args> is the arguments for the "help" command. They are joined with white spaces.

    ghelp("style data");
    
    ## or you can say
    
    ghelp("style", "data");


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

