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
    use Gnuplot::Builder::Dataset;
    
    my $dataset = Gnuplot::Builder::Dataset->new(source => 'f(x)');
    
    my $builder = Gnuplot::Builder::Script->new(<<EOT);
    terminal = png size 500,500 enhanced
    grid     = x y
    xrange   = [-10:10]
    yrange   = [-1:1]
    xlabel   = x offset 0,1
    ylabel   = y offset 1,0
    output   = "sin_wave.png"
    EOT
    
    $builder->unset('key');
    $builder->def('f(x) = sin(pi * x)');
    $builder->plot($dataset);               ## output sin_wave.png
    
    my $child = $builder->child;
    $child->def('f(x) = cos(pi * x)');      ## override parent's setting
    $child->set('output = "cos_wave.png"'); ## override parent's setting
    $child->plot($dataset);                 ## output cos_wave.png


=head1 DESCRIPTION

L<Gnuplot::Builder::Script> is a builder object for a gnuplot script.

The advantages of this module over just printing script text are:

=over

=item *

It keeps option settings and definitions in a hash-like data structure.
So you can change those items individually.

=item *

It accepts code-refs for script sentences, option settings and definitions.
They are evaluated every time it builds the script.

=item *

It supports prototype-based inheritance similar to JavaScript objects.
A child builder can override its parent's settings.

=back

=head1 CLASS METHODS

=head2 $builder = Gnuplot::Builder::Script->new($set_arg)

The constructor. It creates an empty builder.

The optional argument C<$set_arg> is directly given to C<set()> method.

=head1 OBJECT METHODS - BASICS

Most object methods return the object itself, so that you can chain those methods.

=head2 $script = $builder->to_string()

Build and return the gnuplot script string.


=head2 $builder = $buider->add(@sentences)

Add gnuplot script sentences to the C<$builder>.

This is a low-level method. B<< In most cases you should use C<set()> and C<def()> methods below. >>

C<@sentences> is a list of strings and/or code-refs.
A code-ref is evaluated in list context when it builds the script.

Example:

    $builder->add(<<'EOT');
    set title "sample"
    set xlabel "iteration"
    EOT
    my $unit = "sec";
    $builder->add(sub { qq{set ylabel "Time [$unit]"} });

=head1 OBJECT METHODS - GNUPLOT OPTIONS

Methods to manipulate gnuplot options (the "set" and "unset" commands).

=head2 $builder = $builder->set_option($opt_name => $opt_value, ...)

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

    $builder->set_option(
        terminal => 'png size 200,200',
        key      => undef,
    );
    $builder->to_string();
    ## => set terminal png size 200,200
    ## => unset key
        
    $builder->set_option(
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

=back

The options are stored in the C<$builder>'s hash-like structure,
so you can change those options individually.

Even if the options are changed later, their order in the script is unchanged.

    $builder->set_option(
        terminal => 'png size 500,500',
        xrange => '[100:200]',
        output => '"foo.png"',
    );
    $builder->to_string();
    ## => set terminal png size 500,500
    ## => set xrange [100:200]
    ## => set output "foo.png"
    
    $builder->set_option(
        terminal => 'postscript eps size 5.0,5.0',
        output => '"foo.eps"'
    );
    $builder->to_string();
    ## => set terminal postscript eps size 5.0,5.0
    ## => set xrange [100:200]
    ## => set output "foo.eps"

Note that you are free to use any string as C<$opt_name>.
In fact, there may be more than one way to build the same script.

    $builder1->set_option(
        'style data' => 'lines',
        'style fill' => 'solid 0.5'
    );
    $builder2->set_option(
        style => ['data lines', 'fill solid 0.5']
    );

In the above example, C<$builder1> and C<$builder2> generate the same script.
However, C<$builder2> cannot change the style for data individually, while C<$builder1> can.


=head2 $builder = $builder->set($options)

Easy-to-write front-end for C<set_option()> method.

C<$options> is either an array-ref, a hash-ref or a string.

If C<$options> is an array-ref or a hash-ref,
it is equivalent to C<< $builder->set_option(@$options) >> or C<< $builder->set_option(%$options) >>, respectively.

If C<$options> is a string, it is parsed line-by-line to set options.

    $builder->set(<<'EOT');
    xrange = [-5:10]
    output = "foo.png"
    
    ## terminal = png size 100,200
    terminal = pngcairo size 400,800
    
    arrow 1 = from 0,  10 \
              to   10, 0
    EOT

Here is the parsing rule:

=over

=item *

Each line is a pair of option name and value with "=" between them.

    OPT_NAME = OPT_VALUE

=item *

White spaces around OPT_NAME and OPT_VALUE are ignored.

=item *

Lines with a trailing backslash continue to the next line.
The effect is as if the backslash and newline were not there.

=item *

Empty lines are ignored.

=item *

Lines starting with "#" are ignored.

=back


=head2 $builder = $builder->unset($opt_name, ...)

Short-cut for C<< $builder->set_option($opt_name => undef) >>.
It generates "unset" command for the option.

You can specify more that one C<$opt_name>s.

=head2 @opt_values = $builder->get_option($opt_name)

Get the option values for C<$opt_name>.

If C<$opt_name> is set in the C<$builder>, it returns its values.
If a code-ref is set to the C<$opt_name>, it is evaluated and its results are returned.

If C<$opt_name> is not set in the C<$builder>, the values stored in C<$builder>'s parent are returned.
If C<$builder> does not have parent, it returns an empty list.

Always receive the result of this method by an array, because it may return both C<< (undef) >> and C<< () >>.
Returning an C<undef> means the option is "unset" explicitly,
while returning an empty list means no "set" or "unset" sentence for the option.


=head2 $builder = $builder->delete_option($opt_name, ...)

Delete the values for C<$opt_name> from the C<$builder>.
You can specify more than one C<$opt_name>s.

After C<$opt_name> is deleted, C<< $builder->get_option($opt_name) >> will search the C<$builder>'s parent for the values.

Note the difference between C<delete_option()> and C<unset()>.
While C<unset($opt_name)> will generate "unset" sentence for the option,
C<delete_option($opt_name)> will be likely to generate no sentence (well, strictly speaking, it depends on the parent).

C<delete_option($opt_name)> and C<< set_option($opt_name => []) >> are also different if the C<$builder> is a child.
C<set_option()> always overrides the parent setting, while C<delete_option()> resets such overrides.



=head1 OBJECT METHODS - GNUPLOT DEFINITIONS

Methods to manipulate user-defined variables and functions.

All methods in this category are analogous to the methods in L</OBJECT METHODS - GNUPLOT OPTIONS>.
I'm sure you can understand this analogy by this example.

    $builder->set_option(
        xtics => 10,
        key   => undef
    );
    $builder->set_definition(
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


=head2 $builder = $builder->set_definition($def_name => $def_value, ...)

TODO: C<undef> to generate "undefine" command.

=head2 $builder = $builder->def(@def_scripts)

=head2 $builder = $builder->undefine($def_name, ...)

=head2 @def_values = $builder->get_definition($def_name)

=head2 $builder = $builder->delete_definition($def_name, ...)

=head1 OBJECT METHODS - INHERITANCE

Methods about object inheritance.

=head2 $child_builder = $builder->child()

=head2 $parent_builder = $builder->parent()

=head1 OBJECT METHODS - PLOTTING

=head1 OVERRIDES

When you evaluate a C<$builder> as a string, it executes C<< $builder->to_string() >>. That is,

    "$builder" eq $builder->to_string;

=head1 AUTHOR

Toshio Ito, C<< <toshioito at cpan.org> >>

=cut
