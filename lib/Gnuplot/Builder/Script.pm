package Gnuplot::Builder::Script;
use strict;
use warnings;

1;

__END__

=pod

=head1 NAME

Gnuplot::Builder::Script - Object-oriented builder for gnuplot script

=head1 SYNOPSIS

    use Gnuplot::Builder::Script;
    
    my $builder = Gnuplot::Builder::Script->new(<<EOT);
    terminal = png size 500,500 enhanced
    grid     = x y
    xrange   = [-10:10]
    yrange   = [-1:1]
    xlabel   = x offset 0,1
    ylabel   = y offset 1,0
    output   = "sin_wave.png"
    -key
    EOT
    
    $builder->define('f(x) = sin(pi * x)');
    $builder->plot("f(x)");                 ## output sin_wave.png
    
    my $child = $builder->new_child;
    $child->define('f(x) = cos(pi * x)');   ## override parent's setting
    $child->set('output = "cos_wave.png"'); ## override parent's setting
    $child->plot("f(x)");                   ## output cos_wave.png


=head1 DESCRIPTION

L<Gnuplot::Builder::Script> is a builder object for a gnuplot script.

The advantages of this module over just printing script text are:

=over

=item *

It keeps option settings and definitions in a hash-like data structure.
So you can change those items individually.

=item *

It accepts code-refs for script sentences, option settings and definitions.
They are evaluated lazily every time it builds the script.

=item *

It supports prototype-based inheritance similar to JavaScript objects.
A child builder can override its parent's settings.

=back

=head1 CLASS METHODS

=head2 $builder = Gnuplot::Builder::Script->new(@set_args)

The constructor.

The argument C<@set_args> is optional. If it's absent, it creates an empty builder.
If it's set, C<@set_args> is directly given to C<set()> method.

=head1 OBJECT METHODS - BASICS

Most object methods return the object itself, so that you can chain those methods.

=head2 $script = $builder->to_string()

Build and return the gnuplot script string.


=head2 $builder = $buider->add($sentence, ...)

Add gnuplot script sentences to the C<$builder>.

This is a low-level method. B<< In most cases you should use C<set()> and C<def()> methods below. >>

C<$sentences> is a string or a code-ref.
A code-ref is evaluated in list context when it builds the script.
The returned list of strings are added to the script.

You can pass more than one C<$sentence>s.

    $builder->add(<<'EOT');
    set title "sample"
    set xlabel "iteration"
    EOT
    my $unit = "sec";
    $builder->add(sub { qq{set ylabel "Time [$unit]"} });

=head1 OBJECT METHODS - GNUPLOT OPTIONS

Methods to manipulate gnuplot options (the "set" and "unset" commands).

=head2 $builder = $builder->set($opt_name => $opt_value, ...)

Set a gnuplot option named C<$opt_name> to C<$opt_value>.
You can set more than one name-value pairs.

C<$opt_value> is either C<undef>, a string, an array-ref of strings or a code-ref.

=over

=item *

If C<$opt_value> is C<undef>, the "unset" command is generated for the option.

=item *

If C<$opt_value> is a string, the option is set to that string.

=item *

If C<$opt_value> is an array-ref, the "set" command is repeated for each element in it.
If the array is empty, no "set" or "unset" command is generated.

    $builder->set(
        terminal => 'png size 200,200',
        key      => undef,
    );
    $builder->to_string();
    ## => set terminal png size 200,200
    ## => unset key
        
    $builder->set(
        arrow => ['1 from 0,0 to 0,1', '2 from 100,0 to 0,100']
    );
    $builder->to_string();
    ## => set terminal png size 200,200
    ## => unset key
    ## => set arrow 1 0,0 to 0,1
    ## => set arrow 2 from 100,0 to 0,100

=item *

If C<$opt_value> is a code-ref,
it is evaluated in list context when the C<$builder> builds the script.

    @returned_values = $opt_value->($builder, $opt_name)

The C<$builder> and C<$opt_name> are given to the code-ref.

Then, the option is generated as if C<< $opt_name => \@returned_values >> was set.
You can return single C<undef> to "unset" the option.

    my %SCALE_LABEL = (1 => "", 1000 => "k", 1000000 => "M");
    my $scale = 1000;
    $builder->set(
        xlabel => sub { qq{"Traffic [$SCALE_LABEL{$scale}bps]"} },
    );

=back

The options are stored in the C<$builder>'s hash-like structure,
so you can change those options individually.

Even if the options are changed later, their order in the script is unchanged.

    $builder->set(
        terminal => 'png size 500,500',
        xrange => '[100:200]',
        output => '"foo.png"',
    );
    $builder->to_string();
    ## => set terminal png size 500,500
    ## => set xrange [100:200]
    ## => set output "foo.png"
    
    $builder->set(
        terminal => 'postscript eps size 5.0,5.0',
        output => '"foo.eps"'
    );
    $builder->to_string();
    ## => set terminal postscript eps size 5.0,5.0
    ## => set xrange [100:200]
    ## => set output "foo.eps"

Note that you are free to use any string as C<$opt_name>.
In fact, there may be more than one way to build the same script.

    $builder1->set(
        'style data' => 'lines',
        'style fill' => 'solid 0.5'
    );
    $builder2->set(
        style => ['data lines', 'fill solid 0.5']
    );

In the above example, C<$builder1> and C<$builder2> generate the same script.
However, C<$builder2> cannot change the style for "data" or "fill" individually, while C<$builder1> can.


=head2 $builder = $builder->set($options)

If C<set()> method is called with a single string argument C<$options>,
it is parsed to set options.

    $builder->set(<<'EOT');
    xrange = [-5:10]
    output = "foo.png"
    grid
    -key
    
    ## terminal = png size 100,200
    terminal = pngcairo size 400,800
    
    tics = mirror in \
           rotate autojustify
    
    arrow = 1 from 0,10 to 10,0
    arrow = 2 from 5,5  to 10,10
    EOT

Here is the parsing rule:

=over

=item *

Each line is a "set" or "unset" command.

=item *

A "set" line is a pair of option name and value with "=" between them.

    OPT_NAME = OPT_VALUE

=item *

An "unset" line is the option name with leading "-".

    -OPT_NAME

=item *

White spaces around OPT_NAME and OPT_VALUE are ignored.

=item *

If OPT_VALUE is an empty string in "set" line, you can omit "=".

=item *

Lines with a trailing backslash continue to the next line.
The effect is as if the backslash and newline were not there.

=item *

Empty lines are ignored.

=item *

Lines starting with "#" are ignored.

=item *

You can write more than one lines for the same OPT_NAME.
It's the same effect as C<< set($opt_name => [$opt_value1, $opt_value2, ...]) >>.

=back

=head2 $builder = $builder->set_option(...)

C<set_option()> is alias of C<set()>.


=head2 $builder = $builder->unset($opt_name, ...)

Short-cut for C<< set($opt_name => undef) >>.
It generates "unset" command for the option.

You can specify more that one C<$opt_name>s.

=head2 @opt_values = $builder->get_option($opt_name)

Get the option values for C<$opt_name>.

If C<$opt_name> is set in the C<$builder>, it returns its values.
If a code-ref is set to the C<$opt_name>, it is evaluated and its results are returned.

If C<$opt_name> is not set in the C<$builder>, the values of C<$builder>'s parent are returned.
If C<$builder> does not have parent, it returns an empty list.

Always receive the result of this method by an array, because it may return both C<< (undef) >> and C<< () >>.
Returning an C<undef> means the option is "unset" explicitly,
while returning an empty list means no "set" or "unset" sentence for the option.


=head2 $builder = $builder->delete_option($opt_name, ...)

Delete the values for C<$opt_name> from the C<$builder>.
You can specify more than one C<$opt_name>s.

After C<$opt_name> is deleted, C<get_option($opt_name)> will search the C<$builder>'s parent for the values.

Note the difference between C<delete_option()> and C<unset()>.
While C<unset($opt_name)> will generate "unset" sentence for the option,
C<delete_option($opt_name)> will be likely to generate no sentence (well, strictly speaking, it depends on the parent).

C<delete_option($opt_name)> and C<< set($opt_name => []) >> are also different if the C<$builder> is a child.
C<set()> always overrides the parent setting, while C<delete_option()> resets such overrides.


=head1 OBJECT METHODS - GNUPLOT DEFINITIONS

Methods to manipulate user-defined variables and functions.

All methods in this category are analogous to the methods in L</OBJECT METHODS - GNUPLOT OPTIONS>.
I'm sure you can understand this analogy by this example.

    $builder->set(
        xtics => 10,
        key   => undef
    );
    $builder->define(
        a      => 100,
        'f(x)' => 'sin(a * x)',
        b      => undef
    );
    $builder->to_string();
    ## => set xtics 10
    ## => unset key
    ## => a = 100
    ## => f(x) = sin(a * x)
    ## => undefine b


=head2 $builder = $builder->define($def_name => $def_value, ...)

=head2 $builder = $builder->define($definitions)

Set function and variable definitions. See C<set()> method.

=head2 $builder = $builder->set_definition(...)

Alias for C<define()> method.

=head2 $builder = $builder->undefine($def_name, ...)

Short-cut for C<< define($def_name => undef) >>. See C<unset()> method.

=head2 @def_values = $builder->get_definition($def_name)

Get definitions from the C<$builder>. See C<get_option()> method.

=head2 $builder = $builder->delete_definition($def_name, ...)

Delete definitions from the C<$builder>. See C<delete_option()> method.

=head1 OBJECT METHODS - PLOTTING

Methods for plotting.

All plotting methods are non-mutator, that is, they don't change the state of the C<$builder>.
This means you can plot different datasets with the same settings.

Some plotting methods run a gnuplot process background, and let it do the plotting work.
The variable C<$Gnuplot::Builder::GNUPLOT_PATH> is used for the path to the gnuplot executable.
See L<Gnuplot::Builder> for detail.

=head2 $builder = $builder->plot($dataset, ...)

Build the script and plot the given C<$dataset>s with gnuplot's "plot" command.
This method lets a gnuplot process do the actual job.

You can specify more than one C<$dataset>s to plot.

Usually you should use a L<Gnuplot::Builder::Dataset> object for C<$dataset>.
In this case, you can skip reading the rest of this section.

In detail, C<$dataset> is either a string, an array-ref or an object.

=over

=item *

If C<$dataset> is a string, it's treated as the dataset parameters for "plot" command.

    $builder->plot(
        'sin(x) with lines lw 2',
        'cos(x) with lines lw 5',
        '"datafile.dat" using 1:3 with points ps 4'
    );

=item *

If C<$dataset> is an array-ref, it must be an array-ref of a string and a code-ref.

    $dataset = [$params, $data_provider]

C<$params> is the dataset parameters and C<$data_provider> is a code-ref to generate inline data for the dataset.
C<$data_provider> is passed another code-ref (C<$writer>).
C<$data_provider> must call the C<$writer> with the inline data it provides.

    ## @measured_data contains a series of {x => $x_value, y => $y_value}.
    $builder->plot(
        'f(x) title "theoretical" with lines',
        ['"-" using 1:2 title "measured data" with lp', sub {
            my ($writer) = @_;
            foreach my $data_point (@measured_data) {
                $writer->("$data_point->{x} $data_point->{y}");
            }
        }]
    );

You can pass the whole inline data to the C<$writer> at once.

    $builder->plot(['"-" u 1:2', sub { shift->(<<END_DATA) }]);
    1 1
    2 4
    3 9
    4 16
    5 25
    END_DATA

If you don't pass any data to the C<$writer>, the C<plot()> method doesn't generate the inline data section.

=item *

If C<$dataset> is an object and implements C<params_string()> and C<write_data_to()> methods,
it's equivalent to passing

    [$dataset->params_string, sub { my $writer = shift; $dataset->write_data_to($writer) }]

That is, C<params_string()> method is supposed to return a string of dataset parameters,
and C<write_data_to()> method provide the inline data if it has.

L<Gnuplot::Builder::Dataset> implements those methods.

=back

=head2 $script = $builder->plot_string($dataset, ...)

Same as C<plot()> method except it does not pass the script to the gnuplot process
but returns it as a string.

The C<$script> includes the plot settings, "plot" command and inline data if exist.

=head2 $builder = $builder->splot($dataset, ...)

Same as C<plot()> method except it uses "splot" command.

=head2 $script = $builder->splot_string($dataset, ...)

Same as C<plot_string()> method except if uses "splot" command.


=head1 OBJECT METHODS - INHERITANCE

A L<Gnuplot::Builder::Script> object can extend and/or override another object.
This is similar to JavaScript's prototype-based inheritance.

Let C<$parent> and C<$child> be the parent and its child builder, respectively.
Then C<$child> builds a script on top of what C<$parent> builds.
That is,

=over

=item *

Sentences added by C<< $child->add() >> method are appended to the C<$parent>'s script.

=item *

Option settings and definitions in C<$child> are appended to the C<$parent>'s script,
if they are not set in C<$parent>.

=item :

Option settings and definitions in C<$child> are substituted in the C<$parent>'s script,
if they are already set in C<$parent>.

=back


=head2 $builder = $builder->set_parent($parent_builder)

Set C<$parent_builder> as the C<$builder>'s parent.

If C<$parent_builder> is C<undef>, C<$builder> doesn't have a parent anymore.

=head2 $parent_builder = $builder->parent()

Return the C<$builder>'s parent. It returns C<undef> if C<$builder> does not have a parent.

=head2 $child_builder = $builder->new_child()

Create and return a new child builder of C<$builder>.

This is a short-cut for C<< Gnuplot::Builder::Script->new->set_parent($builder) >>.


=head1 OVERRIDES

When you evaluate a C<$builder> as a string, it executes C<< $builder->to_string() >>. That is,

    "$builder" eq $builder->to_string;

=head1 SEE ALSO

L<Gnuplot::Builder::Dataset>

=head1 AUTHOR

Toshio Ito, C<< <toshioito at cpan.org> >>

=cut
