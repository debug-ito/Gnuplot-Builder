package Gnuplot::Builder;
use strict;
use warnings;
use parent qw(Exporter);
use Gnuplot::Builder::Script;
use Gnuplot::Builder::Dataset;
use Gnuplot::Builder::Process;

our $VERSION = "0.22";

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
    return Gnuplot::Builder::Process->with_new_process(do => sub {
        my $writer = shift;
        $writer->("help");
        foreach my $arg (@help_args) {
            $writer->(" $arg");
        }
        $writer->("\n");
    });
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

=head2 For Windows Users

Batch scripts using L<Gnuplot::Builder> are fine in Windows.

In interactive shells, plot windows might not persist when you use regular L<Gnuplot::Builder>.
As a workaround, try L<Gnuplot::Builder::Wgnuplot>.

=head2 Plot Windows

L<Gnuplot::Builder> supports plots in interactive windows.
See L</CONFIGURATION FOR PLOT WINDOWS> for known issues about that.

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

=head1 CONFIGURATION FOR PLOT WINDOWS

L<Gnuplot::Builder> supports plots in interactive windows (terminals
such as "x11", "windows" etc). However, plot windows are very tricky,
so you might have to configure L<Gnuplot::Builder> in advance.

=head2 Design Goals

In terms of plot windows, L<Gnuplot::Builder> aims to achieve the following goals.

=over

=item *

Plotting methods should return immediately, without waiting for plot windows to close.

=item *

Plot windows should persist even after the Perl process using L<Gnuplot::Builder> exits.

=item *

Plot windows should be fully interactive. It should allow zooming and clipping etc.

=back

=head2 Configuration Patterns and Their Problems

The best configuration to achieve the above goals depends on
your platform OS, version of your gnuplot, the terminal to use and the libraries it uses.
Unfortunately there is no one-size-fits-all solution.

If you use Windows, just use L<Gnuplot::Builder::Wgnuplot>.

Otherwise, you have two configuration points.

=over

=item persist mode

Whether or not gnuplot's "persist" mode is used.
This is configured by C<@Gnuplot::Builder::Process::COMMAND> variable.

    @Gnuplot::Builder::Process::COMMAND = qw(gnuplot);           ## persist OFF
    @Gnuplot::Builder::Process::COMMAND = qw(gnuplot --persist); ## persist ON

By default, it's ON.

=item pause mode

Whether or not "pause mouse close" command is used.
This is configured by C<$Gnuplot::Builder::Process::PAUSE_FINISH> variable.

    $Gnuplot::Builder::Process::PAUSE_FINISH = 0; ## pause OFF
    $Gnuplot::Builder::Process::PAUSE_FINISH = 1; ## pause ON

By default, it's OFF.

=back

The above configurations can be set via environment variables.
See L<Gnuplot::Builder::Process> for detail.
Note that B<< the default values for these configurations may be changed in future releases. >>

I recommend "persist: OFF, pause: ON" B<< unless you use "qt" terminal >>.
This makes a fully functional plot window whose process gracefully exits
when you close the window.

Do not use the pause mode if you use "qt" terminal.
This is because, as of gnuplot 4.6.5, "qt" terminal doesn't respond to the "pause" command,
leading to a never-ending process.
This process-leak can be dangerous, so the "pause" mode is OFF by default.

The second best is "persist: ON, pause: OFF".
However, plot windows of "x11" or "qt" terminals in "persist" mode lack interactive functionality
such as zooming and clipping.
"wxt" terminal may be unstable (it crashes or freezes) in some environments.



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

